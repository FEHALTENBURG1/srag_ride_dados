# ---------------------------------------------------------------------------
# 02_filter_clean.R  ->  Filtra RIDE-DF direto sobre o(s) parquet com DuckDB
# e grava o CSV enxuto que será versionado no repositório.
#
# Por que DuckDB + parquet:
#   - lê apenas as linhas que casam o filtro (predicate pushdown);
#   - não carrega o arquivo inteiro na RAM;
#   - resolve a série histórica (vários parquet) com read_parquet([...]).
# ---------------------------------------------------------------------------
source("R/config.R")

library(duckdb)
library(DBI)

arquivos_raw <- readRDS(file.path(dir_raw, "_manifest.rds"))
if (length(arquivos_raw) == 0) stop("Nenhum parquet baixado.")

dir.create(dir_out, showWarnings = FALSE, recursive = TRUE)

con <- dbConnect(duckdb::duckdb())
on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)

# Lista de arquivos como array SQL: ['a.parquet','b.parquet']
lista_arquivos <- paste0("['", paste(arquivos_raw, collapse = "','"), "']")

# Códigos como lista SQL. Comparamos por TEXTO para evitar surpresas de tipo
# (no parquet do SRAG esses campos podem vir como string).
codigos_sql <- paste0("'", paste(codigos_ride, collapse = "','"), "'")

sql <- sprintf("
  COPY (
    SELECT *
    FROM read_parquet(%s, union_by_name = true)
    WHERE CAST(CO_MUN_NOT AS VARCHAR) IN (%s)
       OR CAST(CO_MUN_RES AS VARCHAR) IN (%s)
  ) TO '%s' (FORMAT CSV, HEADER, DELIMITER ',');
", lista_arquivos, codigos_sql, codigos_sql, arquivo_saida)

message("Filtrando RIDE-DF...")
dbExecute(con, sql)

# ---- Verificações ---------------------------------------------------------
n <- dbGetQuery(con, sprintf(
  "SELECT count(*) AS n FROM read_csv_auto('%s')", arquivo_saida))$n
tam_mb <- file.info(arquivo_saida)$size / 1024^2

message(sprintf("Linhas gravadas: %s | Tamanho: %.1f MB", format(n, big.mark="."), tam_mb))

if (tam_mb > limite_mb_github) {
  warning(sprintf(
    "Saída (%.1f MB) acima de %d MB. Considere Git LFS ou GitHub Releases.",
    tam_mb, limite_mb_github))
}
EOF
echo ok