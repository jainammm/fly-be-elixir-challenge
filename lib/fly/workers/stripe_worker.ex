defmodule Fly.Workers.StripeWorker do
  @moduledoc """
  The Background Job worker for Stripe to sync invoice items with stripe.
  """
  @max_attempts Application.compile_env!(:fly, :max_attemps_sync_invoice_item)
  @timeout Application.compile_env!(:fly, :max_execution_time_sync_invoice_item)


  require Logger
  use Oban.Worker, queue: :sync_invoice_item, max_attempts: @max_attempts

  alias Fly.Billing
  alias Fly.Stripe
  alias Fly.Stripe.InvoiceItem
  alias Fly.Stripe.Error

  @doc """
  Sync Invoice Item with Stripe whenever a new Invoice Item is created.

  For testing:
    - I have added a randomness of 25% for giving error and delaying the execution.
    - Oban will retry if we encounter a Stripe Error until maximum retries is reached (3 in this case)
    - Oban will cancel the job if any other unknown error is encountered.
  """
  @impl Oban.Worker
  def perform(%Oban.Job{args: args, attempt: attempt}) do
    Logger.info("Attempt: #{attempt}... Stripe worker started for : #{inspect(args)}")

    with {:ok, invoice_item} <- get_invoice_item_details(args["invoice_item_id"]) do
      try do
        # InvoiceItem.create(invoice_item)        # Should only do this. For testing I have added randomness in errors and execution delay

        random_error_stubbing = Enum.random(1..4)

        case random_error_stubbing do
          1 ->
            Logger.info("Came in clause of error response from Stripe.")

            # Raises an error from Stripe, will fail this job and should get retried if max attempts not reached
            Stripe.error_with(fn ->
              InvoiceItem.retrieve(nil)
            end, %Error{message: "Forcing Error"})

          2 ->
            Logger.info("Came in clause of delayed response from Stripe. It will get timeout by Oban and retried if max attempts is not reached. ")

            # Sleeping for 10 seconds, so this job will fail because of timeout set for 5 seconds
            Stripe.slow_with(fn ->
              InvoiceItem.create(invoice_item)
            end, 10000)

          _ ->
            Logger.info("Came in clause of normal response from Stripe.")

            InvoiceItem.create(invoice_item)
        end
        Logger.info("Stripe worker finished for : #{inspect(args)}")
        :ok
      rescue
        Error ->
          Logger.info("No Worries! Got Stripe Error! Oban will retry if max attempts is not reached.")
          {:error, "Error in StripeWorker for invoice id " <> inspect(args)}
      catch
        _e ->
          Logger.info("Got unexpected error! Cancelling the Job!")
          {:cancel, "Unexpected Error! Cancelling job."}
      end
    end
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.seconds(@timeout)

  @doc """
  Get the invoice item details from invoice ID.
  Returns Fly.Stripe.InvoiceItem object loaded with details to sync.
  """
  def get_invoice_item_details(invoice_item_id) do
    invoice_item = Billing.get_invoice_item!(invoice_item_id)
    {:ok, %{id: invoice_item.id, invoice: invoice_item.invoice, unit_amount_decimal: invoice_item.amount}}
  end

end
