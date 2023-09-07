defmodule FlyWeb.InvoiceItemController do
  use FlyWeb, :controller

  alias Fly.Billing
  alias Fly.Billing.InvoiceItem
  alias Fly.Workers.StripeWorker

  action_fallback FlyWeb.FallbackController

  @doc """
  Creates a new Invoice Item. Pushes job for Oban to sync new Invoice Item with Stripe.

  ## Example

      iex(1)> conn = Phoenix.ConnTest.build_conn() |>
      ...(1)> Phoenix.Controller.put_view(FlyWeb.InvoiceItemJSON) |>
      ...(1)> Phoenix.Controller.put_format(:json)

      iex(2)> invoice_item = %{amount: 1200, description: "Dummy usage"}

      iex(3)> invoice_id = 1

      iex(4)> FlyWeb.InvoiceItemController.create(conn, %{"invoice_item" => invoice_item, "invoice" => invoice_id})

    Output Logs:
      We can see the StripeWorker Job's logs running in the background. It'll sync Invoice Item with Stripe.
  """
  def create(conn, %{"invoice_item" => invoice_item_params, "invoice" => invoice_id}) do
    invoice = Billing.get_invoice!(invoice_id)

    with {:ok, %InvoiceItem{} = invoice_item} <- Billing.create_invoice_item(invoice, invoice_item_params) do
      # Push New Invoice Item ID to Oban for background sync to Stripe
      invoice_item_id = invoice_item.id
      %{invoice_item_id: invoice_item_id}
      |> StripeWorker.new()
      |> Oban.insert()

      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/invoice_items/#{invoice_item}")
      |> render(:show, invoice_item: invoice_item)
    end
  end

  def show(conn, %{"id" => id}) do
    invoice_item = Billing.get_invoice_item!(id)
    render(conn, :show, invoice_item: invoice_item)
  end

  def update(conn, %{"id" => id, "invoice_item" => invoice_item_params}) do
    invoice_item = Billing.get_invoice_item!(id)

    with {:ok, %InvoiceItem{} = invoice_item} <- Billing.update_invoice_item(invoice_item, invoice_item_params) do
      render(conn, :show, invoice_item: invoice_item)
    end
  end

  def delete(conn, %{"id" => id}) do
    invoice_item = Billing.get_invoice_item!(id)

    with {:ok, %InvoiceItem{}} <- Billing.delete_invoice_item(invoice_item) do
      send_resp(conn, :no_content, "")
    end
  end
end
