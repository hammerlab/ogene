let files_have_the_same_contents a b =
  (Core.Std.In_channel.read_all a)
  =
  (Core.Std.In_channel.read_all b)

let strip_chr () =
  Alcotest.(check (list string)) "removed chrs when needed"
    ["1"; "2"; "2"; "MT"; "X"; "JH584295.1"; "GL456382.1"]
    (List.map
       Ogene.strip_chr
       ["chr1"; "chr2"; "2"; "MT"; "chrX"; "JH584295.1"; "chrGL456382.1"])

let sort chr1 rel chr2 =
  let rel_str =
    match rel with
    | `Equal_to -> "="
    | `Less_than -> "<"
    | `Greater_than -> ">"
  in
  Core.Std.sprintf "Sort: %s %s %s" chr1 rel_str chr2,
  `Quick,
  (fun () -> Alcotest.(check int) "removed chrs when needed"
    begin match rel with
    | `Equal_to -> 0
    | `Less_than -> -1
    | `Greater_than -> 1
    end
    (Ogene.compare_contig chr1 chr2))

let sorted_fasta input expected () =
  Alcotest.(check bool) "Sorted FASTA should be what we expect"
    true
    begin
      let output = Core.Std.sprintf "%s.sorted" input in
      Ogene.orderer (Some 60) input output;
      files_have_the_same_contents expected output
    end

let utility_tests = [
  "Remove chr from chromosomes", `Quick, strip_chr;
  sort "X"          `Greater_than "chr2";
  sort "Y"          `Greater_than "chr1";
  sort "X"          `Greater_than "20";
  sort "MT"         `Greater_than "Y";
  sort "Y"          `Less_than    "MT";
  sort "Y"          `Equal_to     "Y";
  sort "2"          `Equal_to     "2";
  sort "2"          `Greater_than "1";
  sort "chr2"       `Greater_than "1";
  sort "chr22"      `Greater_than "18";
  sort "JH584295.1" `Greater_than "18";
  sort "JH584295.1" `Greater_than "GL456370.1";
  sort "MT"         `Less_than    "GL58531.4";
  sort "GL456370.1" `Less_than    "JH584295.1";
]

let sort_tests = [
  "mm10 short-seqs is sorted correctly", `Quick,
  sorted_fasta "_build/test/data/mm10.test.tiny-seqs.fasta" "_build/test/data/mm10.test.tiny-seqs.sorted.fasta";
  "mm10 is sorted correctly", `Quick,
    sorted_fasta "_build/test/data/mm10.test.fasta" "_build/test/data/mm10.test.sorted.fasta";
]


let () =
  Alcotest.run "Test FASTA sorting" [
    "utils", utility_tests;
    "sorting", sort_tests;
  ]
