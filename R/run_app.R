#' Launch the patronage recovery explorer Shiny app
#'
#' Launches an interactive Shiny app that lets a transport policy analyst
#' or journalist explore how each Victorian public transport mode's
#' patronage has changed relative to a pre-pandemic baseline, and whether
#' free-travel periods produced a visible, lasting boost.
#'
#' @param ... Additional arguments passed on to [shiny::runApp()].
#'
#' @return No return value. This function is called for its side effect of
#'   launching the Shiny app in the default web browser (or RStudio/Positron
#'   viewer pane).
#'
#' @importFrom bslib page_sidebar sidebar card card_header
#' @importFrom ggplot2 ggplot aes geom_line labs
#' @importFrom thematic thematic_shiny
#' @importFrom plotly plotlyOutput renderPlotly ggplotly layout
#' @export
run_app <- function(...) {
  app_dir <- system.file("app", package = "vicptpatronage")
  if (app_dir == "") {
    stop(
      "Could not find the app directory. Try re-installing `vicptpatronage`.",
      call. = FALSE
    )
  }
  shiny::runApp(app_dir, ...)
}
