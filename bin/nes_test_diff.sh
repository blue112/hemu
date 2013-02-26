neko out.n nestest.nes --no-colors | sed -re 's/^([A-F0-9]+).+/\1/' | diff - result_pc.log --side-by-side > diff.log
