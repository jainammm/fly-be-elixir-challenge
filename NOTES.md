# A user-friendly Billing System

### Design Philosophy

> I have designed a billing system that strives to provide a seamless user experience within the constraints of third-party rate-limits (in this case, Stripe).

### Architecture Design

*If we were tackling this problem as a 3-month epic, I would design the system as follows:*

- `Fly.io`'s internal Billing microservice acts as a fronting for Stripe.
- **Components**: Server, Database, Message Queue, Worker, Automated-Infra Platform.
- The Server receives usage data, persists it to the database, and enqueues it in a Message Queue for syncing with Stripe.
- When syncing usage data to Stripe, our goal is to provide real-time usage information for users accounting for the constraints of rate-limits.
    - Avoiding rate-limits is paramount because hitting them once will degrade experience of subsequent users, possibly resulting in cascading-failures.
- Assuming that Stripe has a rate-limit of `100 APIs/minute`, we will run workers which are throttled with a concurrency limit of processing `95 Jobs/minute`.
- Our balancing act is achieved by tracking one metric: `queue-size`. Our system will behave appropriately in the given two scenarios:
1. `queue-size` < 1000
    - This is a manageable `queue-size`, which could be cleared within 10 minutes.
    - During low-traffic hours, we should sync *every* `invoice_item` to Stripe, so that users have access to usage and costs in real-time.
1. `queue-size` > 1000
    - A higher queue-size indicates a mismatch between our throughput (more than `100 RPM`) and our capacity to fulfill requests (`95 Jobs/minute`).
    - The worker will switch to a batching strategy in this scenario.
    - Instead of calling Stripe, the worker will group all invoice items into the Invoice for an Organization.
    - When the `group-size` becomes n (n being `queue-size/100`), worker marks the group as ready for sync and enqueues it in the Group Message Queue for syncing with Stripe.
    - By keeping `group-size` variable instead of fixed, I am aiming to minimize UX-degradation and optimize for `queue-size` growing beyond proportion.
    - This strategy ensures we never hit Stripe's rate-limiting while maintaining an acceptable user experience.

> Quoting Murphy's law: _"Anything that can go wrong will go wrong"_. Due to a lack of time, I have not factored in other possibilities that might lead to a bad UX, such as Stripe going down or becoming slow, the Billing service going down, etc.

### Architectural Nuances

- Given billing architecture presumes realistic rate limits and usage throughput.
- My design will fail when the `rate-limit:user` ratio exceeds `1:30`.
- For instance, if the rate-limit is 1000 APIs/day, and number of organizations exceeds 30,000, this billing system will experience a **delay of over 1 month in reporting usage data to Stripe**, which would be unacceptable for our users.
- In the interest of our users, we should negotiate a rate-limit ratio of 1:1. A delay beyond 1 day is unacceptable, and we should consider changing Stripe as an Invoicing partner if reporting usage below 24 hours is not possible.

### Running The Code

- Setup: `mix setup`
- Running tests: `mix test`
- Spin up server: `mix phx.server`

### Solution details

1. I have created CRUD APIs for Invoice, Invoice Item and Organization, and corresponding tests.
1. I have used Oban job-processing library for asynchronously syncing invoice items with Stripe.
1. Whenever an Invoice Item is created, job to sync it with Strip is enqueued in Oban. This happens in a single transaction.

##### RESTful API Routes
```
GET     /api/invoices                    FlyWeb.InvoiceController :index
GET     /api/invoices/:id                FlyWeb.InvoiceController :show
POST    /api/invoices                    FlyWeb.InvoiceController :create
PATCH   /api/invoices/:id                FlyWeb.InvoiceController :update
PUT     /api/invoices/:id                FlyWeb.InvoiceController :update
DELETE  /api/invoices/:id                FlyWeb.InvoiceController :delete
GET     /api/invoices/:id/invoice_items  FlyWeb.InvoiceController :get_invoice_items

GET     /api/invoice_items/:id           FlyWeb.InvoiceItemController :show
POST    /api/invoice_items               FlyWeb.InvoiceItemController :create
PATCH   /api/invoice_items/:id           FlyWeb.InvoiceItemController :update
PUT     /api/invoice_items/:id           FlyWeb.InvoiceItemController :update
DELETE  /api/invoice_items/:id           FlyWeb.InvoiceItemController :delete

GET     /api/organizations               FlyWeb.OrganizationController :index
GET     /api/organizations/:id           FlyWeb.OrganizationController :show
POST    /api/organizations               FlyWeb.OrganizationController :create
PATCH   /api/organizations/:id           FlyWeb.OrganizationController :update
PUT     /api/organizations/:id           FlyWeb.OrganizationController :update
DELETE  /api/organizations/:id           FlyWeb.OrganizationController :delete
GET     /api/organizations/:id/invoices  FlyWeb.OrganizationController :get_invoices
```

##### Stripe Worker

`Fly.Workers.StripeWorker` module syncs Invoice Items with Stripe.

> For testing purpose, I've added randomness for getting error and delayed response from Stripe mock library. The delay I have kept is of 10sec. This worker will timeout in 5 seconds so 

- If error is returned by stripe then Oban will retry it. 
- If an unexpected error occurs then we'll cancel the job
- If response is relayed by stripe and timeout is occured then also Oban will retry it.

##### Testing APIs
For each controllers, we can use a rest client with details in these below files to call the APIs:
- [invoice_controller.rest](api_testing_scripts/invoice_controller.rest)
- [invoice_item_controller.rest](api_testing_scripts/invoice_item_controller.rest)
- [organization_controller.rest](api_testing_scripts/organization_controller.rest)

##### Testing Stripe Worker
1. When Create Invoice Item API is called, job to sync invoice is enqueued. We can use that API mentioned in [invoice_item_controller.rest](api_testing_scripts/invoice_item_controller.rest) file.
1. Inside IEx with `iex -S mix phx.server` 
```
iex(1)> conn = Phoenix.ConnTest.build_conn() |>
...(1)> Phoenix.Controller.put_view(FlyWeb.InvoiceItemJSON) |>
...(1)> Phoenix.Controller.put_format(:json)

iex(2)> invoice_item = %{amount: 1200, description: "Dummy usage"}

iex(3)> invoice_id = 1

iex(4)> FlyWeb.InvoiceItemController.create(conn, %{"invoice_item" => invoice_item, "invoice" => invoice_id})
```

Assuming the Stripe API failed on the first attempt, the response was delayed on the second attempt, and we received a normal response on the third attempt. The logs for this case are displayed below, although they may vary during testing as this occurs randomly. After three attempts, the background job will be marked as `discarded`.
```
[info] Attempt: 1... Stripe worker started for : %{"invoice_item_id" => 59}
[info] Came in clause of error response from Stripe.
[info] No Worries! Got Stripe Error! Oban will retry if max attempts is not reached.

[info] Attempt: 2... Stripe worker started for : %{"invoice_item_id" => 59}
[info] Came in clause of delayed response from Stripe. It will get timedout by Oban and retried if max attempts is not reached. 

[info] Attempt: 3... Stripe worker started for : %{"invoice_item_id" => 59}
[info] Came in clause of normal response from Stripe.
[info] Stripe worker finished for : %{"invoice_item_id" => 59}
```

### Not Implemented

1. We can add `rate-limiting` in Oban however that feature is only for Oban Pro. It can be done using [SmartEngine](https://hexdocs.pm/oban/2.11.0/smart_engine.html).

```
SmartEngine enables truly global concurrency and global rate limiting
This is a Oban Pro feature.
## Docs: https://hexdocs.pm/oban/2.11.0/smart_engine.html
## Example config would look like:
queues: [
 default: 2,
 sync_invoice_item: [
   local_limit: 2,
   global_limit: 10,
   rate_limit: [allowed: 100, period: {1, :hour}]
 ]
]
```

2. Reporting for failed jobs is important. As we'll have to manually debug the issue and background job might fail silently. It can be done as mentioned here in Oban docs - [Handling Expected Failures](https://hexdocs.pm/oban/2.11.0/expected-failures.html)
3. Backoff strategy is important to be configured as per the use case. For now I've kept the default config. It can be done as mentioned here in the Oban Worker docs - [Customizing Backoff ](https://hexdocs.pm/oban/Oban.Worker.html#module-customizing-backoff)


### Avoided Patterns

- My assumption is that users would prefer real-time access to usage and costs.
- The approach I have taken is asynchronous and event-driven, as opposed to scheduled and staggered. Scheduling data sync is less complex; however, it does not adapt to changing patterns in throughput.
- If users prefer daily sync over real-time, scheduling usage data during off-peak hours is also a good enough design.

### Pre-Work

Please find my answers to pre-work questions:
1. Why is it a problem for users when we fail to sync usage data? Why should they care?
    - A delay in synchronization prevents users from monitoring their usage in real time, leading to inefficient utilization of their budget. This can result in higher/lower than anticipated billing, causing frustration and potentially driving churn.
1. Other than the issue you mentioned for (1), what is the worst way the billing system can fail, from the user’s perspective? 
    - If the billing system synchronizes data from previous cycles, that will be the worst scenario from a user's perspective. They might forecast costs based on 2-3 months of usage, and subsequent bills could be much higher than that of previous ones.
    - Billing information for services and products is not clear.

### Parting Thoughts

I enjoy participating in hackathons and contributing to open-source projects. While solving this problem, I had fun learning Phoenix and designing architecture for a unique challenge. Thanks for all the fish!