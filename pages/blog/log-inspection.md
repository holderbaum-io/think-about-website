---
title: "An Ethical Approach to Inspecting Website Traffic"
date: 2020-01-16
tweet: "TODO @ThinkAboutConf #thinkabout19"
author_twitter: "@hldrbm"
author: Jakob
draft: true

---

Organizing a conference requires marketing. And marketing requires website
usage statistics in order to determine effectiveness. But how can user privacy
be ensured?

We wanted to enable us to understand how our website is used. How many clicks
are we generating, where are the users coming from and how frequently are the
different pages beside the landing page visited.

The typical marketing recommendation would be to install Google Analytics or a
similar sophisticated user tracking tool. But this solution is quite far
detached from an ethical approach to website statistics.

This article shall give a slightly technical perspective on the solution we
decided on and which implications it has on potential website visitors.

## The Short Explanation

Classical approaches like Google Analytics focus on user tracking. That means,
they try to identify individual users (by IP, Cookies, Browser Headers, and
many more dirty tricks) and store and observe their behaviour on the website.
And this works well and gives the owners a deep insight into ways the website
is used.

We believe this approach to be deeply unethical. Individual should not be
observed while using random websites on the internet.

That's why we focused on something else: Server Statistics. The following
information really matter to us from a marketing research perspective:

* How many people are visiting our website daily
* When are the traffic peaks
* Where are people coming from (e.g. Twitter or Xing)
* How frequently are pages beside the landing page visited

All those questions can either be answered by spying on individuals or by
simply analyzing the server statistics. We don't know which session went to the
tickets page after looking at our keynotes. But we can say that statistically a
certain percentage of users visits the tickets page after looking at the
landing page.

We use the open source software [GoAccess](https://goaccess.io/), they have an
example on their website that shows a live snapshot of their traffic. Take a
look:

![Example website statistic generated using GoAccess](/assets/images/blog/log-inspection/example-graph.png)

Those statistical perspectives are more than enough to adapt marketing
strategies and web layouts to optimize your conversion. And all those answers
can be had without ever looking at an individual user.

And to understand how users behave or where the website is frustrating, there
is a method called "User Testing". You sit down with a potential user
voluntarily and observe them while using your website. This gives you a great
insight on how your product is perceived without spying on every person using
it.

On a side note: If you go with such a statistical approach combined with IP
masking, you don't even need to display a consent button. Because you just
really don't track your users at all.

## The Technical Explanation

Up until this section, the post focuses on the narrative behind our decision to
refrain from user tracking. This section will be a deep dive into how we
achieved this and which technical steps we took to generate our statistics
using [GoAccess](https://goaccess.io/).

In it's easiest form, GoAccess simply takes any webserver log file as an input
and produces a static HTML page with your statistics as an output. So simply
run this command on your server to produce some statistics:

~~~
goaccess access.log -a -o report.html
~~~

The resulting report file is a self-contained HTML page which can be served or
just downloaded and opened in your browser. It will look more or less exactly
like the screenshot you saw a bit up further.

### Focus on User Privacy

As mentioned further up, you can configure GoAccess to anonymize the user IPs
it stores. Simply provide this flag when executing GoAccess:

~~~
goaccess --anonymize-ip [..]
~~~

This will replace the last segment of each occuring IP to zero. For example
`123.45.93.12` and `123.45.93.77` both become `123.45.93.00`.

### Building Statistics on rotating Logs

A typical linux webserver setup uses the software `logrotate` to rotate the
access logs daily. This means by the end of every day, the current logfile is
archived and a new empty one is created. This makes deleting older logs simpler
and mitigates extreme log file growth.

Ubuntu and Debian both install and configure `logrotate` automatically when
`nginx` or `apache` is installed. In this default setup, logs are rotated
daily.

To be able to generate an ever growing statistic over all our webserver logs,
we have to configure `GoAccess` to store its logs in a database. In addition to
this, we have to extend `logrotate` to call `GoAccess` whenever a log is
rotated by the end of the day.

In the case of `nginx` there is a configuration file at
`/etc/logrotate.d/nginx`looking like this or similar:

~~~
/var/log/nginx/*.log {
  daily
  missingok
  rotate 52
  compress
  delaycompress
  notifempty
  create 640 nginx adm
  sharedscripts
  postrotate
    if [ -f /var/run/nginx.pid ]; then
      kill -USR1 `cat /var/run/nginx.pid`
    fi
  endscript
}
~~~

This configuration file determines how those logs are rotated. Take a closer
look at the `postrotate` section. It contains a shell script that will be
executed once whenever the logs are rotated. With the `daily` modifier in the
first line that would mean exactly once a day. We can use this hook to include
our `GoAccess` call.

Besides creating an immediate report HTML, `GoAccess` can also create a
database for its statistics to which logs can be appended. The call would then
look like this:

~~~
mkdir -p /var/log/goaccessdb
goaccess \
  access.log \
  --db-path /var/log/goaccessdb \
  --keep-db-files \
  --load-from-disk \
  --process-and-exit \
  --log-format=COMBINED
~~~

*Important Sidenote:* In order to be able to create such a database, you need
to have TokyoCabinet support in your goaccess version. The goaccess deb
repositories provide this version of goaccess via the package `goaccess-tcb`.

Now the command above creates a directory `/var/log/goaccessdb` and fills it
with statistics from the provided log file. This command can then be reexecuted
with another log file, and the statistics will be extended accordingly.

So simply update your logrotate config from above to look like this:

~~~
/var/log/nginx/*.log {
  daily
  [...]
  postrotate
    if [ -f /var/run/nginx.pid ]; then
      kill -USR1 `cat /var/run/nginx.pid`
    fi
    mkdir -p /var/log/goaccessdb
    goaccess \
      /var/log/nginx/access.log.1 \
      --anonymize-ip \
      --ignore-crawlers\
      --db-path /var/log/goaccessdb \
      --keep-db-files \
      --load-from-disk \
      --process-and-exit \
      --log-format=COMBINED
  endscript
}
~~~

Now with every log rotations, `logrotate` will call `GoAccess` and feed it the
newly archived logfile (`access.log.1`). So day by day, the statistics about
your website traffic will be stored in the database at `/var/log/goaccessdb`.

Note the `--anonymize-ip` option. It will make sure, that all IPs are stored
anonymized which is advisable for privacy reasons.

Additionally there is an option `--ignore-crawlers` which will ignore all type
of crawlers. I usually like to use this flag, since the statistics will then
reflect actual users only, no automated bots. Which after all is the audience
for which we are optimizing the website.

### Displaying Statistics from the Database

As mentioned, the configurations above will continuously create a database of
anonymized website statistics in the configured folder. You can than use
`GoAccess` again, to create an HTML report out of this database:

~~~
goaccess \
  --anonymize-ip \
  --ignore-crawlers\
  --db-path /var/log/goaccessdb \
  --keep-db-files \
  --load-from-disk \
  --log-format=COMBINED \
  -o report.html
~~~

This will create a file called `report.html` which contains all statistics
stored in the database as a self-contained website. Ideally you generate this
file onto a path which is served by your webserver. By doing so, you can access
is from the web whenever you want.
