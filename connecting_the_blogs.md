
# Connecting the Blogs
In the hugo.toml of sydneytech, benburke, and leonardkoan, the shared media base URL is defined for that specific site, and the shared repository is imported:

## Ini, TOML


[params.media]
  # For BenBurke.org, this points to its specific folder in the bucket
  r2BaseUrl = "[https://media.sydneytech.org/benburke](https://media.sydneytech.org/benburke)"

[module]
  [[module.imports]]
    path = "[github.com/BernardBurke/hugo-shared-components](https://github.com/BernardBurke/hugo-shared-components)"