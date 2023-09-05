defmodule FlyWeb.InvoiceControllerTest do
  use FlyWeb.ConnCase

  import Fly.BillingFixtures
  import Fly.OrganizationFixtures

  alias Fly.Billing.Invoice

  @create_attrs %{
    due_date: ~D[2023-07-01],
    invoiced_at: nil,
    stripe_id: nil
  }
  @update_attrs %{

  }
  @invalid_attrs %{
    # due_date: "invalid_date",
    invoiced_at: nil,
    stripe_id: nil
  }

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all invoices", %{conn: conn} do
      conn = get(conn, ~p"/api/invoices")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create invoice" do
    setup [:create_organization]

    test "renders invoice when data is valid", %{conn: conn, org: org} do
      organization_id = org.id

      conn = post(conn, ~p"/api/invoices", invoice: @create_attrs, organization: organization_id)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/invoices/#{id}")

      assert %{
               "id" => ^id
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, org: org} do
      organization_id = org.id

      conn = post(conn, ~p"/api/invoices", invoice: @invalid_attrs, organization: organization_id)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update invoice" do
    setup [:create_invoice]

    test "renders invoice when data is valid", %{conn: conn, invoice: %Invoice{id: id} = invoice} do
      conn = put(conn, ~p"/api/invoices/#{invoice}", invoice: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/invoices/#{id}")

      assert %{
               "id" => ^id
             } = json_response(conn, 200)["data"]
    end
  end

  describe "delete invoice" do
    setup [:create_invoice]

    test "deletes chosen invoice", %{conn: conn, invoice: invoice} do
      conn = delete(conn, ~p"/api/invoices/#{invoice}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/invoices/#{invoice}")
      end
    end
  end

  defp create_invoice(_) do
    org = organization_fixture()

    invoice = invoice_fixture(org)
    %{invoice: invoice}
  end

  defp create_organization(_) do
    org = organization_fixture()

    %{org: org}
  end
end
