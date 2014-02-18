webrake
=======

Webrake is a static website generator leveraging Rake FileTasks with simple extension and customisation allowing explicit control of how files are processed


## API


```
Site.new(
  Rake.application, 
  FileSystem.new('src'),
  :filters => { 
    '*.erb' => Filters::Erb.new, 
    '*.css.less' => Filters::Less.new
  },
  :dependencies => {
    ['typography.less', 'reset.less'] => 'concatenated_style.css.less',
    '*.html' => 'sitemap.txt'
  },
  :output => { 
    '*.html' => Layout::Erb.new('actual/layout/default.html.erb'),
    'blog/*.html' => Layout::Erb.new('actual/layout/blog.html.erb')
  }
)
```

## Example

```
sitemap.txt.erb
  <%= files(output['/**/*.html']).each do |f| ... end %>

style.css.less.erb
  <%= concatenate(files(%w(base.less typography.less))) %>

blog.html.erb
  <%= @posts = files('source/blog/*.html').sort_by(&:created_at) %>
```
