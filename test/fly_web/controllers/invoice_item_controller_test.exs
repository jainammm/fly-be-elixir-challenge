defmodule FlyWeb.InvoiceItemControllerTest do
  use FlyWeb.ConnCase

  import Fly.BillingFixtures
  import Fly.OrganizationFixtures

  alias Fly.Billing.InvoiceItem

  @create_attrs %{
    amount: 1200,
    description: "Dummy usage"
  }
  # @update_attrs %{

  # }
  @invalid_attrs %{
    description: "Dummy usage"
  }

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  # describe "index" do
  #   test "lists all invoice_items", %{conn: conn} do
  #     conn = get(conn, ~p"/api/invoice_items")
  #     assert json_response(conn, 200)["data"] == []
  #   end
  # end

  describe "create invoice_item" do
    setup [:create_invoice]

    test "renders invoice_item when data is valid", %{conn: conn, invoice: invoice} do
      invoice_id = invoice.id

      conn = post(conn, ~p"/api/invoice_items", invoice_item: @create_attrs, invoice: invoice_id)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/invoice_items/#{id}")

      assert %{
               "id" => ^id
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, invoice: invoice} do
      invoice_id = invoice.id

      conn = post(conn, ~p"/api/invoice_items", invoice_item: @invalid_attrs, invoice: invoice_id)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  # describe "update invoice_item" do
  #   setup [:create_invoice_item]

  #   test "renders invoice_item when data is valid", %{conn: conn, invoice_item: %InvoiceItem{id: id} = invoice_item} do
  #     conn = put(conn, ~p"/api/invoice_items/#{invoice_item}", invoice_item: @update_attrs)
  #     assert %{"id" => ^id} = json_response(conn, 200)["data"]

  #     conn = get(conn, ~p"/api/invoice_items/#{id}")

  #     assert %{
  #              "id" => ^id
  #            } = json_response(conn, 200)["data"]
  #   end

  #   test "renders errors when data is invalid", %{conn: conn, invoice_item: invoice_item} do
  #     conn = put(conn, ~p"/api/invoice_items/#{invoice_item}", invoice_item: @invalid_attrs)
  #     assert json_response(conn, 422)["errors"] != %{}
  #   end
  # end

  # describe "delete invoice_item" do
  #   setup [:create_invoice_item]

  #   test "deletes chosen invoice_item", %{conn: conn, invoice_item: invoice_item} do
  #     conn = delete(conn, ~p"/api/invoice_items/#{invoice_item}")
  #     assert response(conn, 204)

  #     assert_error_sent 404, fn ->
  #       get(conn, ~p"/api/invoice_items/#{invoice_item}")
  #     end
  #   end
  # end

  # defp create_invoice_item(_) do
  #   org = organization_fixture()
  #   invoice = invoice_fixture(org)

  #   invoice_item = invoice_item_fixture(invoice)
  #   %{invoice_item: invoice_item}
  # end

  defp create_invoice(_) do
    org = organization_fixture()

    invoice = invoice_fixture(org)
    %{invoice: invoice}
  end
end
