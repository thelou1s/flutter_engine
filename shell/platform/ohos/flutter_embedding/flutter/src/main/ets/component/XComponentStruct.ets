@Component
struct XComponentStruct {
  private context:ESObject;
  dvModelParams: DVModelParameters = new DVModelParameters();

  build() {
    XComponent({ id: (this.dvModelParams as Record<string, ESObject>)["xComponentId"], type: 'texture', libraryname: 'flutter'})
      .onLoad((context) => {
        this.context = context;
      })
      .onDestroy(() => {
      })
  }
}

@Builder export function BuildXComponentStruct(buildParams: BuilderParams) {
  XComponentStruct({dvModelParams: buildParams.params});
}