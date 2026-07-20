# Orquestra o pipeline completo. Rode com: Rscript run_pipeline.R
source("R/01_download.R")
source("R/02_filter_clean.R")
message("Pipeline concluído. Saída: data/dados_limpos_df.csv")
