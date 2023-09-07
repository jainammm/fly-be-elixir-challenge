defmodule Fly.Workers.StripeWorker do
  @max_attempts Application.compile_env!(:fly, :max_attemps_sync_invoice_item)

  require Logger
  use Oban.Worker, queue: :sync_invoice_item, max_attempts: @max_attempts

  alias Fly.Billing
  alias Fly.Stripe
  alias Fly.Stripe.InvoiceItem
  alias Fly.Stripe.Error

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    Logger.info("Stripe worker started for : #{inspect(args)}")

    with {:ok, invoice_item} <- get_invoice_item_details(args["invoice_item_id"]) do
      try do
        random_error_stubbing = Enum.random(1..4)

        case random_error_stubbing do
          1 ->
            Logger.info("Came in clause of error response from Stripe.")

            Stripe.error_with(fn ->
              InvoiceItem.retrieve(nil)
            end, %Error{message: "Forcing Error"})

          2 ->
            Logger.info("Came in clause of delayed response from Stripe.")

            Stripe.slow_with(fn ->
              InvoiceItem.create(invoice_item)
            end, 1000)

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
          Logger.info("Got unexpected error! Cancelling the Job")
          {:cancel, "Unexpected Error! Cancelling job."}
      end
    end
  end

  def get_invoice_item_details(invoice_item_id) do
    invoice_item = Billing.get_invoice_item!(invoice_item_id)
    {:ok, %{id: invoice_item.id, invoice: invoice_item.invoice, unit_amount_decimal: invoice_item.amount}}
  end

end
