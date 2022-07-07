import { FlowNavigationNextEvent,FlowNavigationBackEvent,FlowAttributeChangeEvent,FlowNavigationFinishEvent } from 'lightning/flowSupport';
import { LightningElement } from 'lwc';


export function nextStep(contexto){
    console.log('FlowHelper NEXT');
    const nextNavigationEvent = new FlowNavigationNextEvent();
    contexto.dispatchEvent(nextNavigationEvent);
}


export function priorStep(contexto){
    console.log('FlowHelper BACK');
    contexto.dispatchEvent(new FlowNavigationBackEvent());
}

export function finishFlow(contexto){
    console.log('FlowHelper FinishFlow');
    contexto.dispatchEvent(new FlowNavigationFinishEvent());
}

export function updateFlowVariable(contexto,varName,value){
    console.log('updateFlowVariable '+varName+' to '+value);
    if(varName){
        contexto.dispatchEvent(new FlowAttributeChangeEvent(varName,value));
    }else{
        console.error('No se ha informado el nombre de la variable');
    }
    
}