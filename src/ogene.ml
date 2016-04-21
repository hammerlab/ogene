open Core_kernel.Std
open Biocaml_unix


(** Return the contig name from a Fasta.item description *)
let contig item =
  let desc = item.Fasta.description in
  let toks = String.split ~on:' ' desc in
  match toks with
  | [] -> None
  | ctg::_ -> Some ctg


let contig_exn item =
  match contig item with
  | Some contig -> contig
  | None ->
    failwith (sprintf "Can't parse contig from item with description %s"
                item.Fasta.description)


(** Remove the 'chr' prefix from a string, if it's there.  *)
let strip_chr c =
  if String.is_prefix c ~prefix:"chr"
  then String.drop_prefix c 3
  else c


(** Format the description of an item for output into a FASTA.  *)
let description_string item =
  ">" ^ item.Fasta.description


(** Slice of string str from s to e (or to the end of the string, if e is beyond
    that. *)
let rec safe_slice str s e =
  try
    let sub = String.slice str s e in
    if sub = "" then None else Some sub
  with _ ->
  try
    let length = String.length str in
    safe_slice str (Int.min s length) length
  with _ -> None


(** Produce a stream of strings from Fasta.items. *)
let stringify_fasta
    ?(sequence_line_length=60) (header, items) : string Stream.t =
  let location : [`In_header of int |
                  `In_items of int * [`Desc | `Sequence of int]] ref =
    ref (`In_header 0) in
  let rec next idx =
    match !location with
    | `In_header h ->
      begin match List.nth header h with
      | Some l ->
        location := `In_header (h + 1);
        Some l
      | None ->
        location := `In_items (0, `Desc);
        next idx
      end
    | `In_items (idx, where) ->
      (* We're going to move into the sequence after yielding the description,
         if there an item here; otherwise, we're done (yield None) *)
      begin match List.nth items idx with
      | None -> None
      | Some item ->
        begin match where with
        | `Desc ->
          location := `In_items (idx, `Sequence 0);
          Some (description_string item)
        | `Sequence offset ->
          let next_offset = offset + sequence_line_length in
          let sequence = item.Fasta.sequence in
          begin match safe_slice sequence offset next_offset with
          | None ->
            location := `In_items (idx+1, `Desc);
            next idx
          | Some subseq ->
            location := `In_items (idx, `Sequence next_offset);
            Some subseq
          end
        end
      end
  in
  Stream.from next


(** Return 1 if a > b, 0 if equal, and -1 if b > a.

That is, if a sorts above b in karyotypic order. *)
let compare_contig a b =
  let special_contigs = ["X"; "Y"; "MT"; "M"] in
  let special_cmp a b =
    let a_idx, _ = Option.value_exn (List.findi ~f:(fun i c -> c = a) special_contigs) in
    let b_idx, _ = Option.value_exn (List.findi ~f:(fun i c -> c = b) special_contigs) in
    Int.compare a_idx b_idx
  in
  let a = strip_chr a in
  let b = strip_chr b in
  let int_a = try Some (Int.of_string a) with _ -> None in
  let int_b = try Some (Int.of_string b) with _ -> None in
  match int_a, int_b with
  | Some _, None -> -1
  | None, Some _ -> 1
  | Some a, Some b -> Int.compare a b
  | None, None ->
    let special_a = List.mem special_contigs a in
    let special_b = List.mem special_contigs b in
    begin match special_a, special_b with
    | true, false -> -1
    | false, true -> 1
    | false, false -> String.compare a b
    | true, true -> special_cmp a b
    end


let order ic =
  let fasta = Fasta.read ic in
  let (header, sequences) = match fasta with
  | Ok res -> res
  | Error _ -> failwith "Can't read fasta"
  in
  let sorted_contigs =
    let rec descs ?(acc=[]) stream =
      let next_contig =
        try Some (Stream.next stream)
        with Stream.Failure -> None
      in
      match next_contig with
      | None -> acc
      | Some item ->
        let item = ok_exn item in
        descs stream ~acc:(item::acc)
    in
    descs sequences
    |> List.sort ~cmp:(fun a b -> compare_contig (contig_exn a) (contig_exn b))
  in
  (header, sorted_contigs)


let orderer sequence_line_length input_file output_file =
  let ic = open_in input_file in
  let oc = open_out output_file in
  let header, contigs = order ic in
  let () = In_channel.close ic in
  (* TODO: can't get the string list from Fasta.header...? passing empty list
     for now *)
  let fasta = stringify_fasta ?sequence_line_length ([], contigs) in
  Stream.iter (fun s -> output_string oc s; output_char oc '\n') fasta;
  Out_channel.close oc
