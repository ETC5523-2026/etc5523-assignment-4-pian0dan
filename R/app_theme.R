# Colour palette and bslib theme for the bundled Shiny app (inst/app/app.R).
# These are internal (non-exported) package objects, accessed from the app
# via `:::`, since the app ships inside this package rather than as a
# separate consumer of its public API.

# Official Public Transport Victoria mode colours, taken directly from the
# DTP's "Transport Pictograms" asset files (CC BY 4.0; see
# inst/app/www/icons/ATTRIBUTION.md): blue for metropolitan train, green for
# tram, orange for bus, and purple for regional services. PTV's pictogram
# set only distinguishes two regional shades (train, coach), both a
# magenta-leaning purple (hue ~285-300deg); "Regional bus" has no official
# colour of its own, so it uses a third, more blue-violet purple (hue
# ~267deg) rather than a simple interpolation, so it reads as clearly
# distinct from both official shades rather than a shade "in between" them.
mode_colors <- c(
  "Metropolitan train" = "#0072CE",
  "Metropolitan tram" = "#78BE20",
  "Metropolitan bus" = "#FF8200",
  "Regional train" = "#7F0D82",
  "Regional coach" = "#A57FB2",
  "Regional bus" = "#7A3AC9"
)

# Pictogram shown next to each mode in the filter checkboxes. PTV has no
# distinct symbol for regional (vs. metropolitan) bus, so "Regional bus"
# reuses the generic bus shape but recoloured to match its line colour
# above (see inst/app/www/icons/ATTRIBUTION.md for provenance).
mode_icons <- c(
  "Metropolitan train" = "icons/train.png",
  "Metropolitan tram" = "icons/tram.png",
  "Metropolitan bus" = "icons/bus.png",
  "Regional train" = "icons/regional_train.png",
  "Regional coach" = "icons/coach.png",
  "Regional bus" = "icons/regional_bus.png"
)

# Shading intensity roughly tracks discount intensity: weekend-only free
# travel affected far fewer days per month than the later every-day free
# and half-price periods. These are injected directly into plotly's JSON
# (shapes/marker specs in app.R), bypassing ggplot2's usual colour-to-hex
# translation, so they must be real hex codes: plotly.js's CSS parser
# silently rejects R-only names like "grey88" (not valid CSS), leaving
# shading invisible and legend swatches falling back to default colours.
fare_period_colors <- c(
  "Weekend free travel" = "#E0E0E0",
  "Free travel (every day)" = "#666666",
  "Half-price fares" = "#A6A6A6"
)

# Colour theming for the app's chrome (sidebar, cards, buttons, headings).
# transport.vic.gov.au itself blocks automated fetches, so these values
# are taken from the stylesheet actually served by the Department of
# Transport and Planning's Open Data portal (the same department behind
# Transport Victoria), fetched directly from:
# https://opendata.transport.vic.gov.au/webassets/base/1c87a999_main.css
#   --bs-primary / .btn-primary background: #206b82 (teal-blue)
#   --bs-success: #3A833A (green) - repurposed here as the app's accent
#   .accordion-button:not(.collapsed) background: #e9f0f3
#   body font: no custom webfont is loaded; it relies on the Bootstrap
#   default system sans-serif stack, which this theme also uses.
# This is distinct from `mode_colors` above, which must stay fixed to
# PTV's official per-mode colours for the data encoding to remain
# meaningful; only the surrounding chrome is themed here.
app_theme <- bslib::bs_theme(
  version = 5,
  bg = "#FBFBFA",
  fg = "#1B1B1B",
  primary = "#206b82",
  secondary = "#3A833A"
) |>
  bslib::bs_add_rules(
    "
    .card { border-radius: 0.65rem; box-shadow: 0 2px 10px rgba(32, 107, 130, 0.1); }
    .accordion-button:not(.collapsed) {
      background-color: #e9f0f3;
      color: $primary;
    }
    "
  )
