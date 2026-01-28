# LWC Test Guidance

Only write Jest tests for components with meaningful logic. Skip tests for basic component creation and simple event handling unless the user requests them.

When testing, cover:
- Complex conditional logic
- Data transformations
- Wire adapter error handling

## Test Structure

Structure each test with the arrange-act-assert pattern:
```javascript
it('does something expected', async () => {
    // Arrange
    const element = createElement('c-my-component', { is: MyComponent });

    // Act
    document.body.appendChild(element);
    await flushPromises();

    // Assert
    const result = element.shadowRoot.querySelector('div');
    expect(result.textContent).toBe('Expected');
});
```

## DOM Queries

Query the shadow DOM for assertions:
```javascript
element.shadowRoot.querySelector('lightning-button')
element.shadowRoot.querySelectorAll('.item')
```

## Async Operations

Always flush promises after DOM changes or when testing reactive properties:
```javascript
await flushPromises();
```

## Wire Adapters

Mock wire adapters using `@salesforce/sfdx-lwc-jest`:
```javascript
import { getRecord } from 'lightning/uiRecordApi';

getRecord.emit(mockData);
getRecord.error(mockError);
```