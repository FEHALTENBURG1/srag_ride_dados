# ---------------------------------------------------------------------------
# 01_download.R  ->  Descobre e baixa o PARQUET mais recente do SRAG.
# Brutos NÃO entram no Git (ver .gitignore).
# ---------------------------------------------------------------------------
source("R/config.R")

dir.create(dir_raw, showWarnings = FALSE, recursive = TRUE)

urls_srag <- resolver_urls_srag()
if (length(urls_srag) == 0) stop("Não foi possível resolver nenhuma URL do SRAG.")

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
