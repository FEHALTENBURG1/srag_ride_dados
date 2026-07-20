# ---------------------------------------------------------------------------
# 01_download.R  ->  Baixa os PARQUET brutos do SRAG para data-raw/
# Brutos NÃO entram no Git (ver .gitignore).
# ---------------------------------------------------------------------------
source("R/config.R")

dir.create(dir_raw, showWarnings = FALSE, recursive = TRUE)

if (length(urls_srag) == 0) {
  stop("Nenhuma URL definida. Ajuste `urls_srag` em R/config.R ou a env SRAG_URLS.")
}

baixar <- function(url) {
  destino <- file.path(dir_raw, basename(sub("\\?.*$", "", url)))
  if (file.exists(destino)) {
    message("Já existe, pulando: ", destino)
    return(destino)
  }
  message("Baixando: ", url)
  options(timeout = max(3600, getOption("timeout")))
  utils::download.file(url, destino, mode = "wb", quiet = FALSE)
  destino
}

arquivos_raw <- vapply(urls_srag, baixar, character(1))
saveRDS(arquivos_raw, file.path(dir_raw, "_manifest.rds"))
message("Download concluído: ", length(arquivos_raw), " arquivo(s).")
