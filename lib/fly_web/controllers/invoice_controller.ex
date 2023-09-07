defmodule FlyWeb.InvoiceController do
  use FlyWeb, :controller

  alias Fly.Billing
  alias Fly.Organizations
  alias Fly.Billing.Invoice

  action_fallback FlyWeb.FallbackController

  def index(conn, _params) do
    invoices = Billing.list_invoices()
    render(conn, :index, invoices: invoices)
  end

  def create(conn, %{"invoice" => invoice_params, "organization" => organization_id}) do
    org = Organizations.get_organization!(organization_id)

    with {:ok, %Invoice{} = invoice} <- Billing.create_invoice(org, invoice_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/invoices/#{invoice}")
      |> render(:show, invoice: invoice)
    end
  end

  def show(conn, %{"id" => id}) do
    invoice = Billing.get_invoice!(id)
    render(conn, :show, invoice: invoice)
  end

  def update(conn, %{"id" => id, "invoice" => invoice_params}) do
    invoice = Billing.get_invoice!(id)

    with {:ok, %Invoice{} = invoice} <- Billing.update_invoice(invoice, invoice_params) do
      render(conn, :show, invoice: invoice)
    end
  end

  def delete(conn, %{"id" => id}) do
    invoice = Billing.get_invoice!(id)

    with {:ok, %Invoice{}} <- Billing.delete_invoice(invoice) do
      send_resp(conn, :no_content, "")
    end
  end

  def get_invoice_items(conn, %{"id" => id}) do
    invoice_items = Billing.get_invoice_items_by_invoice(id)
    render(conn, :index, invoice_items: invoice_items)
  end
end
