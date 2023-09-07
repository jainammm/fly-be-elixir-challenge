defmodule FlyWeb.InvoiceJSON do
  alias Fly.Billing.InvoiceItem
  alias Fly.Billing.Invoice

  @doc """
  Renders a list of invoices.
  """
  def index(%{invoices: invoices}) do
    %{data: for(invoice <- invoices, do: data(invoice))}
  end

  def index(%{invoice_items: invoice_items}) do
    %{data: for(invoice_items <- invoice_items, do: data(invoice_items))}
  end

  @doc """
  Renders a single invoice.
  """
  def show(%{invoice: invoice}) do
    %{data: data(invoice)}
  end

  defp data(%Invoice{} = invoice) do
    %{
      id: invoice.id
    }
  end

  defp data(%InvoiceItem{} = invoice_item) do
    %{
      id: invoice_item.id
    }
  end
end
