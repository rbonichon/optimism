./cannon/bin/cannon load-elf --path=./op-program/bin/op-program-client.elf

./cannon/bin/cannon run \
    --pprof.cpu \
    --info-at '%10000' \
    --proof-at never \
    --input ./state.json \
    -- ./op-program.sh 
