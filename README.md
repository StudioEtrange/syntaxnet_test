# SyntaxNet Test

## Install on Nix


  git clone https://github.com/StudioEtrange/syntaxnet_test
  cd syntaxnet_test
  ./do.sh syntaxnet install
  ./do.sh syntaxnet build
  ./do.sh syntaxnet test


## Test prebuilt languages

  cd syntaxnet_test
  ./do.sh lang install -l French
  ./do.sh lang test -l French -- je mange du chocolat
