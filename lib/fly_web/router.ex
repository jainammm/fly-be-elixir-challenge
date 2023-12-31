defmodule FlyWeb.Router do
  use FlyWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {FlyWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", FlyWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  scope "/api", FlyWeb do
    pipe_through :api

    resources "/invoices", InvoiceController, except: [:new, :edit]
    resources "/invoice_items", InvoiceItemController, except: [:new, :index, :edit]
    resources "/organizations", OrganizationController, except: [:new, :edit]

    get("/invoices/:id/invoice_items", InvoiceController, :get_invoice_items)

    get("/organizations/:id/invoices", OrganizationController, :get_invoices)
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:fly, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: FlyWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
