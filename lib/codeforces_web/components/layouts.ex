defmodule CodeforcesWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use CodeforcesWeb, :controller` and
  `use CodeforcesWeb, :live_view`.
  """
  use CodeforcesWeb, :html

  embed_templates "layouts/*"
end
