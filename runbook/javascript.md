# Angular

### Observables
- **Arrow function (`next: (value) => { ... }`):**
  - Arrow functions do **not** have their own `this` context.
  - They inherit `this` from the surrounding scope (in this case, your service class).
  - So, inside the arrow function, `this.ldContext` refers to your service’s property as expected.

- **Regular function (`next(value) { ... }`):**
  - Regular functions have their own `this` context, which is set by how the function is called.
  - In the context of RxJS’s `subscribe`, `this` inside `next(value) { ... }` refers to the observer object, **not** your service instance.
  - As a result, `this.ldContext` is undefined or causes an error.
