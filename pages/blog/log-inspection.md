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
