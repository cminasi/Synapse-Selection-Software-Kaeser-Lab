#@ UIService ui

consolePane = ui.getDefaultUI().getConsolePane().getComponent()

component = consolePane
while (!(component instanceof java.awt.Window)) {
	component = component.getParent()
}

component.resize(1, 1)
component.move(1, 1)