FROM jekyll/jekyll:pages

RUN gem install webrick
RUN gem install jekyll-theme-slate

EXPOSE 4000

CMD ["jekyll", "serve", "--watch", "--force_polling"]
