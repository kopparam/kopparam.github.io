FROM ruby:latest

WORKDIR /home/site
ADD ./ /home/site

EXPOSE 4000

RUN bundle install

CMD jekyll serve

