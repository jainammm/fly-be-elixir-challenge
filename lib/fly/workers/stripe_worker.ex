defmodule Fly.Workers.StripeWorker do
  use Oban.Worker, queue: :sync_invoice_item

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    IO.inspect("Started Working...")
    IO.inspect(args)
    IO.inspect("...Finished Working!")
    :ok
  end

end
