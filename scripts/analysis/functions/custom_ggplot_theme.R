theme_custom <-
  theme_minimal(base_size = 20) +
  theme(
    strip.text = element_text(
      hjust = .5,
      size = 20
    ),
    plot.background = element_rect(fill = "white", color = "transparent"),
    plot.title = element_text(size = 28, hjust = .5, face = "bold"),
    legend.box.background = element_rect(color = "transparent"),
    legend.position = "none"
  )