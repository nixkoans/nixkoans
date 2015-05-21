export PATH="${coreutils}/bin:${clang}/bin"
mkdir $out
clang -I/usr/include -o $out/simple $src
