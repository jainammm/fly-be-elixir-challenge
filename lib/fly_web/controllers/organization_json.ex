defmodule FlyWeb.OrganizationJSON do
  alias Fly.Billing.Invoice
  alias Fly.Organizations.Organization

  @doc """
  Renders a list of organizations.
  """
  def index(%{organizations: organizations}) do
    %{data: for(organization <- organizations, do: data(organization))}
  end

  def index(%{invoices: invoices}) do
    %{data: for(invoices <- invoices, do: data(invoices))}
  end

  @doc """
  Renders a single organization.
  """
  def show(%{organization: organization}) do
    %{data: data(organization)}
  end

  defp data(%Organization{} = organization) do
    %{
      id: organization.id,
      name: organization.name,
      stripe_customer_id: organization.stripe_customer_id
    }
  end

  defp data(%Invoice{} = invoice) do
    %{
      id: invoice.id
    }
  end
end
