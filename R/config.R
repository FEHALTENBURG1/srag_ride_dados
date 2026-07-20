# ---------------------------------------------------------------------------
# config.R  ->  Parâmetros centrais do pipeline
# ---------------------------------------------------------------------------

# Municípios que compõem a RIDE-DF (código IBGE de 6 dígitos, sem DV)
codigos_ride <- c(
  530010L, # Distrito Federal
  # Goiás
  520010L, 520017L, 520025L, 520030L, 520060L, 520080L,
  520320L, 520400L, 520530L, 520549L, 520551L, 520580L,
  520620L, 520790L, 520800L, 520860L, 521250L, 521305L,
  521460L, 521523L, 521560L, 521730L, 521760L, 521975L,
  522000L, 522068L, 522185L, 522220L, 522230L,
  # Minas Gerais
  310450L, 310930L, 310945L, 317040L
)

# ---------------------------------------------------------------------------
# Fonte bruta (OpenDATASUS - dataset "SRAG 2019 a 2026").
# Usamos o PARQUET: colunar, comprimido e consultável de forma "lazy".
# O nome do arquivo carrega a DATA da revisão (INFLUD26-DD-MM-AAAA), então
# ele muda a cada atualização. Prefira passar a URL via variável de ambiente
# SRAG_URLS no GitHub Actions em vez de fixar a data aqui.
#
# Página do recurso:
# https://dadosabertos.saude.gov.br/dataset/srag-2019-a-2026
# ---------------------------------------------------------------------------
urls_srag <- {
  env <- Sys.getenv("SRAG_URLS", "")
  if (nzchar(env)) {
    trimws(strsplit(env, ",")[[1]])
  } else {
    c(
      "https://s3.sa-east-1.amazonaws.com/ckan.saude.gov.br/SRAG/2026/INFLUD26-20-07-2026.parquet"
      # adicione outros anos se precisar da série histórica, ex:
      # "https://s3.sa-east-1.amazonaws.com/ckan.saude.gov.br/SRAG/2025/INFLUD25-....parquet"
    )
  }
}

# Caminhos
dir_raw       <- "data-raw"                          # brutos (NÃO versionados)
dir_out       <- "data"                              # saída versionada no Git
arquivo_saida <- file.path(dir_out, "dados_limpos_df.csv")

# Limite de segurança para commit no GitHub (MB). Acima disso, use Git LFS.
limite_mb_github <- 90
