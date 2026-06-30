pub mod Plugin.Renderer {
  pub trait Renderer[t] {
    type Aef: Eff
    pub def render(renderer: t, state: List[Task]): Unit \ Renderer.Aef[t]
  }
}
