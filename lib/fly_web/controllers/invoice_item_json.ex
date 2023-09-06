defmodule FlyWeb.InvoiceItemJSON do
  alias Fly.Billing.InvoiceItem

  @doc """
  Renders a list of invoice_items.
  """
  def index(%{invoice_items: invoice_items}) do
    %{data: for(invoice_item <- invoice_items, do: data(invoice_item))}
  end

  @doc """
  Renders a single invoice_item.
  """
  def show(%{invoice_item: invoice_item}) do
    %{data: data(invoice_item)}
  end

  defp data(%InvoiceItem{} = invoice_item) do
    %{
      id: invoice_item.id
    }
  end
end
