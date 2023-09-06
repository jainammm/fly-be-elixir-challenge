defmodule Fly.BillingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Fly.Billing` context.
  """

  @doc """
  Generate an invoice.
  """
  def invoice_fixture(organization, attrs \\ %{}) do
    attrs = attrs
            |> Enum.into(%{
              due_date: ~D[2023-07-22],
              invoiced_at: ~U[2023-07-22 12:39:00Z],
              stripe_id: "some stripe_id"
            })

    {:ok, invoice} = Fly.Billing.create_invoice(organization, attrs)

    invoice
  end

  @doc """
  Generate an invoice item.
  """
  def invoice_item_fixture(invoice, attrs \\ %{}) do
    attrs = attrs
            |> Enum.into(%{
              amount: 1200,
              description: "VM usage",
            })

    {:ok, invoice_item} = Fly.Billing.create_invoice_item(invoice, attrs)

    invoice_item
  end
end
