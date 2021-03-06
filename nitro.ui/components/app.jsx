import React from 'react'
import { Router } from 'react-router-dom'
import { DragDropContext } from 'react-beautiful-dnd'
import createBrowserHistory from 'history/createBrowserHistory'
const history = createBrowserHistory()

import { NitroSdk, authEvents } from '../../nitro.sdk'
import { UiService } from '../services/uiService.js'
import { Shell } from './shell/index.jsx'
import { Login } from './login/index.jsx'
import { ContextMenu } from './contextMenu.jsx'
import { Modal } from './modal.jsx'
import { ShortcutsModal } from './shortcutsModal.jsx'
import { TutorialModal } from './tutorialModal.jsx'

class App extends React.Component {
  state = {
    signedIn: NitroSdk.isSignedIn()
  }
  componentDidMount() {
    document.addEventListener('visibilitychange', this.triggerWindowVisibility)
    NitroSdk.bind(authEvents.SIGN_IN, this.signInCallback)
    NitroSdk.bind(authEvents.SIGN_IN_ERROR, this.signInError)
  }
  componentWillUnmount() {
    document.removeEventListener(
      'visibilitychange',
      this.triggerWindowVisibility
    )
    NitroSdk.unbind(authEvents.SIGN_IN, this.signInCallback)
    NitroSdk.unbind(authEvents.SIGN_IN_ERROR, this.signInError)
  }
  signInCallback = () => {
    history.replace('/')
    this.setState({
      signedIn: NitroSdk.isSignedIn()
    })
  }
  signInError = () => {
    history.replace('/')
  }
  triggerDragEnd = result => {
    // no destination or the order hasn't changed
    if (
      !result.destination ||
      result.source.index === result.destination.index
    ) {
      return
    }
    // currently not supported moving tasks to different lists
    if (
      result.source.droppableId === 'tasksDroppable' &&
      result.destination.droppableId === 'tasksDroppable'
    ) {
      const order = UiService.state.currentListTasksOrder.slice()
      order.splice(result.source.index, 1)
      order.splice(
        result.destination.index,
        0,
        result.draggableId.split('tasks-')[1]
      )
      NitroSdk.updateTasksOrder(UiService.state.currentList, order)
    } else if (
      result.source.droppableId === 'listsDroppable' &&
      result.destination.droppableId === 'listsDroppable'
    ) {
      const order = UiService.state.currentListsOrder.slice()
      order.splice(result.source.index, 1)
      order.splice(
        result.destination.index,
        0,
        result.draggableId.split('lists-')[1]
      )
      NitroSdk.updateListsOrder(order)
    }
  }
  triggerWindowVisibility = () => {
    // triggers a sync if the window becomes active and there hasn't been a sync within 30s
    if (
      !document.hidden &&
      NitroSdk.lastSync !== undefined &&
      new Date().getTime() - NitroSdk.lastSync.getTime() > 30000
    ) {
      NitroSdk.fullSync(true)
    }
  }
  render() {
    if (!this.state.signedIn || window.location.pathname === '/callback') {
      return <Login />
    }
    return (
      <React.Fragment>
        <Router history={history}>
          <DragDropContext onDragEnd={this.triggerDragEnd}>
            <Shell />
          </DragDropContext>
        </Router>
        <Modal />
        <ShortcutsModal />
        <TutorialModal />
        <ContextMenu />
      </React.Fragment>
    )
  }
}
export default App
