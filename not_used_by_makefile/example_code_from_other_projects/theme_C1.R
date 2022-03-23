theme_C1 <-
  theme_minimal(base_size = 16) +
  theme(
    strip.text = element_text(
      hjust = .5,
      size = 20
    ),
    plot.background = element_rect(fill = "white", color = "transparent"),
    plot.title = element_text(size = 26, hjust = .5),
    legend.box.background = element_rect(color = "transparent"),
    legend.position = "none"
  )
