pub mod Plugin.Renderer {
  use AppState.AppState

  pub trait Renderer[t] {
    type Aef: Eff
    pub def render(renderer: t, state: AppState): Unit \ Renderer.Aef[t]
  }
}
