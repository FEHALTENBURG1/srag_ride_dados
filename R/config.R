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
# Descoberta automática da URL do parquet mais recente.
# O arquivo do OpenDATASUS rotaciona a cada semana (INFLUD26-DD-MM-AAAA),
# entao NAO fixamos a data: perguntamos ao CKAN qual e o arquivo atual.
# ---------------------------------------------------------------------------
dataset_ckan_id <- "srag-2019-a-2026"   # id do dataset no OpenDATASUS
ckan_base       <- "https://dadosabertos.saude.gov.br"

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0 || identical(a, "")) b else a

# Extrai a data DD-MM-AAAA do nome do arquivo, se houver.
.data_do_url <- function(u) {
  m <- regmatches(u, regexpr("\\d{2}-\\d{2}-\\d{4}", u))
  if (length(m) == 0 || m == "") return(as.Date(NA))
  as.Date(m, format = "%d-%m-%Y")
}

# Plano B: constroi a URL a partir da segunda-feira mais recente.
.url_por_segunda <- function() {
  hoje    <- Sys.Date()
  # %u: 1=segunda ... 7=domingo -> recua ate a segunda desta semana
  segunda <- hoje - ((as.integer(format(hoje, "%u")) - 1))
  ano     <- format(segunda, "%Y")
  yy      <- substr(ano, 3, 4)
  sprintf("https://s3.sa-east-1.amazonaws.com/ckan.saude.gov.br/SRAG/%s/INFLUD%s-%s.parquet",
          ano, yy, format(segunda, "%d-%m-%Y"))
}

# Resolve a(s) URL(s) de download, nesta ordem de prioridade:
#   1) variavel de ambiente SRAG_URLS (fixa manualmente, se quiser)
#   2) descoberta via API do CKAN (recomendado)
#   3) plano B: URL construida pela segunda-feira mais recente
resolver_urls_srag <- function() {
  env <- Sys.getenv("SRAG_URLS", "")
  if (nzchar(env)) {
    message("Usando SRAG_URLS do ambiente.")
    return(trimws(strsplit(env, ",")[[1]]))
  }

  descoberta <- tryCatch({
    if (!requireNamespace("jsonlite", quietly = TRUE))
      stop("pacote jsonlite ausente")
    api <- sprintf("%s/api/3/action/package_show?id=%s", ckan_base, dataset_ckan_id)
    resp <- jsonlite::fromJSON(api, simplifyVector = FALSE)
    if (!isTRUE(resp$success)) stop("CKAN retornou success=false")

    recursos <- resp$result$resources
    parquet <- Filter(function(r) {
      fmt <- tolower(r$format %||% "")
      url <- tolower(r$url %||% "")
      fmt == "parquet" || grepl("\\.parquet$", url)
    }, recursos)
    if (length(parquet) == 0) stop("nenhum recurso .parquet no dataset")

    urls  <- vapply(parquet, function(r) r$url, character(1))
    datas <- do.call(c, lapply(urls, .data_do_url))

    escolhido <- if (any(!is.na(datas))) {
      urls[which.max(datas)]                       # arquivo com a data mais nova
    } else {
      lm <- vapply(parquet, function(r) r$last_modified %||% "", character(1))
      urls[which.max(lm)]                          # fallback: last_modified
    }
    message("URL descoberta via CKAN: ", escolhido)
    escolhido
  }, error = function(e) {
    message("Descoberta via CKAN falhou (", conditionMessage(e),
            "). Usando plano B por data.")
    NULL
  })

  if (!is.null(descoberta)) return(descoberta)

  plano_b <- .url_por_segunda()
  message("URL (plano B) por segunda-feira: ", plano_b)
  plano_b
}

# Caminhos
dir_raw       <- "data-raw"
dir_out       <- "data"
arquivo_saida <- file.path(dir_out, "dados_limpos_df.csv")

# Limite de segurança para commit no GitHub (MB). Acima disso, use Git LFS.
limite_mb_github <- 90
