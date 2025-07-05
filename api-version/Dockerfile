FROM ruby:3.3.6

RUN apt-get update -qq && apt-get install -y \
  build-essential \
  default-mysql-client \
  nodejs \
  vim

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]
