open Ogene

let cmd =
  let open Cmdliner in
  let doc = "sort a fasta karyotypically" in
  let version = "0.0.0" in
  let sequence_line_length =
    let doc = "The length of the sequence section lines." in
    Arg.(value & opt (some int) (Some 60) & info ["line-length"; "L"] ~doc)
  in
  let input_file =
    let doc = "The input fasta file to be sorted." in
    Arg.(required & pos 0 (some file) None & info ~doc [])
  in
  let output_file =
    let doc = "The output fasta file to be written." in
    Arg.(required & pos 1 (some string) None & info ~doc [])
  in
  let man = [
    `S "Description";
    `P "$(tname) sorts a given fasta karyotypically, \
        e.g. 1, 2, ..., 22, ... X, Y, MT, ...";
    `P "To sort a fasta";
    `P "$(tname) input.fasta output.fasta";
  ] in
  Term.(const orderer $ sequence_line_length $ input_file $ output_file),
  Term.(info "orderer" ~version ~doc ~man)


let () = match Cmdliner.Term.eval cmd with `Error _ -> exit 1 | _ -> exit 0
