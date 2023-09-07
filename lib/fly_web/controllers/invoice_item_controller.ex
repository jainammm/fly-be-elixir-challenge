defmodule FlyWeb.InvoiceItemController do
  use FlyWeb, :controller

  alias Fly.Billing
  alias Fly.Billing.InvoiceItem
  alias Fly.Workers.StripeWorker

  action_fallback FlyWeb.FallbackController

  # def index(conn, _params) do
  #   invoice_items = Billing.list_invoice_items()
  #   render(conn, :index, invoice_items: invoice_items)
  # end

  def create(conn, %{"invoice_item" => invoice_item_params, "invoice" => invoice_id}) do
    invoice = Billing.get_invoice!(invoice_id)

    with {:ok, %InvoiceItem{} = invoice_item} <- Billing.create_invoice_item(invoice, invoice_item_params) do
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

  # def update(conn, %{"id" => id, "invoice_item" => invoice_item_params}) do
  #   invoice_item = Billing.get_invoice_item!(id)

  #   with {:ok, %InvoiceItem{} = invoice_item} <- Billing.update_invoice_item(invoice_item, invoice_item_params) do
  #     render(conn, :show, invoice_item: invoice_item)
  #   end
  # end

  # def delete(conn, %{"id" => id}) do
  #   invoice_item = Billing.get_invoice_item!(id)

  #   with {:ok, %InvoiceItem{}} <- Billing.delete_invoice_item(invoice_item) do
  #     send_resp(conn, :no_content, "")
  #   end
  # end
end
