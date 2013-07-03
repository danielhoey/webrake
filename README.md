webrake
=======

Static website generation using rake file tasks

## API
rules: glob -> filters
output: output directory
files: get files with frontmatter(?)

## Example

```
rules(
  '.erb' => Erb.new
  ['.markdown','.md'] => Markdown.new
  '.html' => [ErbLayout.new('default.html.erb'), output]
  'blog/*.html' => [ErbLayout.new('post.html.erb'), output]
  'style.css.less' => [Less.new, output]
)

sitemap.txt.erb
  <%= files(output['/**/*.html']).each do |f| ... end %>

style.css.less.erb
  <%= concatenate(files(%w(base.less typography.less))) %>

blog.html.erb
  <%= @posts = files('source/blog/*.html').sort_by(&:created_at) %>
```
