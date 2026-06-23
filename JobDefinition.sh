nextflow \
   -C /Users/matt/Developer/GitHub/cloudBasic/pipeline/nextflow.config \
   run /Users/matt/Developer/GitHub/cloudBasic/pipeline/stem.nf \
   -profile local \
   -params-file /Users/matt/Developer/GitHub/cloudBasic/pipeline/params/defaults.json \
   --execute all \
   --supplementary ""
