defmodule Fly.Billing do
  @moduledoc """
  The Billing context.

  This file was generated using:
  `mix phx.gen.context Billing Invoice invoices`
  """

  import Ecto.Query, warn: false
  alias Fly.Repo

  alias Fly.Billing.Invoice
  alias Fly.Billing.InvoiceItem
  alias Fly.Organizations.Organization
  alias Fly.Workers.StripeWorker

  defmodule BillingError do
    defexception message: "billing error"
  end

  @doc """
  Returns the list of invoices.

  ## Examples

      iex> list_invoices()
      [%Invoice{}, ...]

  """
  def list_invoices(opts \\ []) do
    preload = Keyword.get(opts, :preload, [:invoice_items])

    from(Invoice, preload: ^preload)
    |> Repo.all()
  end

  @doc """
  Gets a single invoice.

  Raises `Ecto.NoResultsError` if the Invoice does not exist.

  ## Examples

      iex> get_invoice!(123)
      %Invoice{}

      iex> get_invoice!(456)
      ** (Ecto.NoResultsError)

  """
  def get_invoice!(id, opts \\ []) do
    preload = Keyword.get(opts, :preload, [])

    from(i in Invoice, preload: ^preload)
    |> Repo.get!(id)
  end

  @doc """
  Creates a invoice.

  ## Examples

      iex> create_invoice(%{field: value})
      {:ok, %Invoice{}}

      iex> create_invoice(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_invoice(%Organization{} = organization, attrs \\ %{}) do
    %Invoice{}
    |> Invoice.organization_changeset(organization, attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a invoice.

  ## Examples

      iex> update_invoice(invoice, %{field: new_value})
      {:ok, %Invoice{}}

      iex> update_invoice(invoice, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_invoice(%Invoice{} = invoice, attrs) do
    invoice
    |> Invoice.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a invoice.

  ## Examples

      iex> delete_invoice(invoice)
      {:ok, %Invoice{}}

      iex> delete_invoice(invoice)
      {:error, %Ecto.Changeset{}}

  """
  def delete_invoice(%Invoice{} = invoice) do
    Repo.delete(invoice)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking invoice changes.

  ## Examples

      iex> change_invoice(invoice)
      %Ecto.Changeset{data: %Invoice{}}

  """
  def change_invoice(%Invoice{} = invoice, attrs \\ %{}) do
    Invoice.changeset(invoice, attrs)
  end

  @doc """
  Gets a single invoice item.

  Raises `Ecto.NoResultsError` if the Invoice Item does not exist.

  ## Examples

      iex> get_invoice_item!(123)
      %InvoiceItem{}

      iex> get_invoice_item!(456)
      ** (Ecto.NoResultsError)

  """
  def get_invoice_item!(id, opts \\ []) do
    preload = Keyword.get(opts, :preload, [])

    from(i in InvoiceItem, preload: ^preload)
    |> Repo.get!(id)
  end

  @doc """
  Add Invoice Item to Invoice
  """
  def create_invoice_item(%Invoice{} = invoice, attrs) do
    InvoiceItem.invoice_changeset(invoice, %InvoiceItem{}, attrs)
    |> Repo.insert()
  end

  @doc """
  Add Stripe Worker Job in Oban.
  """
  def insert_stripe_worker_job(invoice_item_id) do
    %{invoice_item_id: invoice_item_id}
    |> StripeWorker.new()
    |> Oban.insert()
  end

  @doc """
  Create Invoice Item and insert Stripe Worker Oban Job in a single database transaction.
  """
  def create_invoice_item_transaction(%Invoice{} = invoice, attrs) do
    Repo.transaction(fn->
      case create_invoice_item(invoice, attrs) do
        {:ok, invoice_item} ->
          case insert_stripe_worker_job(invoice_item.id) do
            {:ok, _} -> {invoice_item}
            {:error, error} -> Repo.rollback(error)
          end
          invoice_item
        {:error, error} -> Repo.rollback(error)
      end
    end)
  end

  @doc """
  Updates a invoice_item.

  ## Examples

      iex> update_invoice_item(invoice_item, %{field: new_value})
      {:ok, %InvoiceItem{}}

      iex> update_invoice_item(invoice_item, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_invoice_item(%InvoiceItem{} = invoice_item, attrs) do
    invoice_item
    |> InvoiceItem.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a invoice_item.

  ## Examples

      iex> delete_invoice_item(invoice_item)
      {:ok, %InvoiceItem{}}

      iex> delete_invoice_item(invoice_item)
      {:error, %Ecto.Changeset{}}

  """
  def delete_invoice_item(%InvoiceItem{} = invoice_item) do
    Repo.delete(invoice_item)
  end

  @doc """
  Gets all InvoiceItems for a particular Invoice.
  """
  def get_invoice_items_by_invoice(invoice_id) do
    from(i in InvoiceItem ,where: i.invoice_id == ^invoice_id)
    |> Repo.all()
  end
end
