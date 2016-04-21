# What is this?

This is a small program that karyotypically sorts a fasta file. 

That is, say you have a fasta file with contigs in lexicographic order, for example, the first contig is 1 (or chr1) and the second is 10, then 11, and so forth; GATK and other tools may not be too happy about this. You can solve this by running this tool:

```shell
fasta-orderer unsorted-fasta.fa sorted-fasta.fa 
```

You'll likely have to wait a couple minutes (~1 minute for a 3GB fasta on my computer), as the entire fasta is loaded into memory. Sorry.

Now, the contigs will be in order from 1, 2, ..., 22, ..., X, Y, MT, ... and so forth.

And that's all there is to it.

## Building

You'll need [`opam`](https://opam.ocaml.org/) (probably a `brew install opam` away from you, at most), and then you'll need to do the following:

```shell
make deps
make
```

Installing these dependencies might take a few minutes; for that, your forgiveness is begged.

From here, you should be good to go.

## Contributing

Contributions welcome; please see the Github issues page.

## Testing

You'll need to `opam testDeps`, then run the tests with `make all; make test`.
