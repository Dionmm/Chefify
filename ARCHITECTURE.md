# Chefify Architecture & Implementation Plan

## 1. System Overview

Chefify is an AI-powered meal planning application that intelligently selects recipes based on user preferences while optimizing ingredient usage to minimize food waste.

## 2. Core Features

### 2.1 User Criteria & Preferences
- **Dietary restrictions** (allergens, vegetarian, vegan, etc.)
- **Cuisine preferences** (ranking system)
- **Nutritional goals** (calorie targets, macro distribution)
- **Time constraints** (max cooking time per meal)
- **Seasonal preferences**
- **Budget constraints**
- **Family size/portions needed**

### 2.2 AI-Powered Recipe Selection
- **Palette learning** from user ratings and selections
- **Ingredient optimization** algorithm to maximize cross-meal usage
- **Variety balancing** (cuisine types, proteins, cooking methods)
- **Seasonal awareness** using the season field in recipes

### 2.3 Shopping List Management
- **Persistent shopping list** per user
- **Smart input parsing** for quantity and units
- **Automatic addition** when meals are added to meal plan
- **Intelligent aggregation** of ingredients
- **Unit conversion** (metric units only)
- **Check-off functionality** for purchased items
- **Store section grouping** (produce, dairy, etc.)

## 3. Technical Architecture

### 3.1 Backend Architecture (C#/.NET 8)
```
/Chefify.Api
  /Controllers
    - RecipesController.cs
    - MealPlansController.cs
    - ShoppingListController.cs
    - PreferencesController.cs
  /Middleware
    - AuthenticationMiddleware.cs
    - ErrorHandlingMiddleware.cs
  
/Chefify.Core
  /Domain
    /Entities       
      - User.cs
      - Recipe.cs (readonly from existing DB)
      - MealPlan.cs
      - ShoppingListItem.cs
    /ValueObjects   
      - Ingredient.cs
      - NutritionalInfo.cs
      - Quantity.cs
      - Unit.cs
  /Interfaces
    /Repositories   
    /Services       

/Chefify.Application
  /Services
    - RecipeRecommendationService.cs
    - IngredientOptimizationService.cs
    - ShoppingListService.cs
    - MealPlanningService.cs
    - UnitConversionService.cs
    - QuantityParsingService.cs
  /DTOs             
  /Validators       
  /Mappings         

/Chefify.Infrastructure
  /Data
    /Repositories   
    /Migrations     
    /Context        
  /External
    /AI             
    /Auth           
  
/Chefify.Tests
  /Unit
    /Domain         - Entity and value object tests
    /Application    - Service layer tests
    /Parsers        - Quantity parsing tests
  /Integration
    /Api            - Controller tests
    /Database       - Repository tests
```

### 3.2 Frontend Architecture (React/TypeScript)
```
/src
  /components
    /common        
      - Button.tsx
      - Card.tsx
      - Modal.tsx
      - LoadingSpinner.tsx
    /recipes       
      - RecipeCard.tsx
      - RecipeDetail.tsx
      - RecipeSearch.tsx
    /meal-planning 
      - WeeklyCalendar.tsx
      - MealSlot.tsx
      - MealPlanSummary.tsx
    /shopping      
      - ShoppingList.tsx
      - ShoppingListItem.tsx
      - AddItemForm.tsx
    /preferences   
      - PreferencesForm.tsx
      - DietaryRestrictions.tsx
  
  /hooks          
    - useAuth.ts
    - useRecipes.ts
    - useShoppingList.ts
  /services       
    - api.ts
    - authService.ts
  /store          
    - authStore.ts
    - shoppingListStore.ts
    - mealPlanStore.ts
  /utils          
  /styles         - Tailwind configurations
```

### 3.3 Database Schema (Simplified Units)
```sql
-- User management (simplified for OIDC)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    external_id VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- User preferences
CREATE TABLE user_preferences (
    user_id UUID PRIMARY KEY REFERENCES users(id),
    dietary_restrictions TEXT[],
    disliked_ingredients TEXT[],
    cuisine_preferences JSONB,
    max_cook_time_minutes INTEGER,
    daily_calorie_target INTEGER,
    household_size INTEGER DEFAULT 2,
    preferred_meal_types TEXT[]
);

-- Meal plans
CREATE TABLE meal_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    week_start_date DATE,
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT NOW()
);

-- Meal plan recipes
CREATE TABLE meal_plan_recipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    meal_plan_id UUID REFERENCES meal_plans(id),
    recipe_id VARCHAR(255) REFERENCES recipes.recipes(objectid),
    day_of_week INTEGER CHECK (day_of_week >= 0 AND day_of_week <= 6),
    meal_type VARCHAR(50),
    portions INTEGER DEFAULT 2,
    added_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(meal_plan_id, day_of_week, meal_type)
);

-- Shopping list items
CREATE TABLE shopping_list_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    ingredient_id VARCHAR(255) REFERENCES recipes.ingredients(id),
    custom_name VARCHAR(255),
    quantity DECIMAL NOT NULL,
    unit VARCHAR(50) NOT NULL,
    is_checked BOOLEAN DEFAULT FALSE,
    store_section VARCHAR(100),
    source VARCHAR(50) DEFAULT 'manual',
    recipe_id VARCHAR(255),
    added_at TIMESTAMP DEFAULT NOW(),
    checked_at TIMESTAMP,
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Recipe ratings
CREATE TABLE recipe_ratings (
    user_id UUID REFERENCES users(id),
    recipe_id VARCHAR(255) REFERENCES recipes.recipes(objectid),
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (user_id, recipe_id)
);

-- Supported units (simplified)
CREATE TABLE supported_units (
    unit_code VARCHAR(50) PRIMARY KEY,
    unit_name VARCHAR(100),
    unit_type VARCHAR(50),
    to_base_multiplier DECIMAL,
    base_unit VARCHAR(50)
);

INSERT INTO supported_units (unit_code, unit_name, unit_type, to_base_multiplier, base_unit) VALUES
-- Volume
('tsp', 'teaspoon', 'volume', 5, 'ml'),
('tbsp', 'tablespoon', 'volume', 15, 'ml'),
('ml', 'millilitres', 'volume', 1, 'ml'),
('l', 'litres', 'volume', 1000, 'ml'),
-- Weight
('g', 'grams', 'weight', 1, 'g'),
('kg', 'kilograms', 'weight', 1000, 'g'),
-- Other
('cm', 'centimetres', 'length', 1, 'cm'),
('handful', 'handful', 'approximate', 1, 'handful');
```

## 4. Test-First Development Approach

### 4.1 Unit Value Object (TDD Example)
```csharp
// Start with tests: Chefify.Tests/Unit/Domain/UnitTests.cs
public class UnitTests
{
    [Fact]
    public void Unit_ShouldOnlyAcceptValidUnits()
    {
        // Arrange & Act & Assert
        Assert.Throws<InvalidUnitException>(() => new Unit("cups"));
        Assert.Throws<InvalidUnitException>(() => new Unit("oz"));
        
        var validUnit = new Unit("g");
        Assert.Equal("g", validUnit.Code);
    }
    
    [Theory]
    [InlineData("tsp", UnitType.Volume)]
    [InlineData("g", UnitType.Weight)]
    [InlineData("handful", UnitType.Approximate)]
    public void Unit_ShouldIdentifyCorrectType(string code, UnitType expectedType)
    {
        var unit = new Unit(code);
        Assert.Equal(expectedType, unit.Type);
    }
}

// Then implement: Chefify.Core/Domain/ValueObjects/Unit.cs
public class Unit : ValueObject
{
    private static readonly HashSet<string> ValidUnits = new()
    {
        "tsp", "tbsp", "ml", "l", "g", "kg", "cm", "handful"
    };
    
    public string Code { get; }
    public UnitType Type { get; }
    
    public Unit(string code)
    {
        if (!ValidUnits.Contains(code))
            throw new InvalidUnitException($"'{code}' is not a supported unit");
            
        Code = code;
        Type = DetermineType(code);
    }
}
```

### 4.2 Quantity Parsing Service (TDD)
```csharp
// Tests first: Chefify.Tests/Unit/Application/QuantityParsingServiceTests.cs
public class QuantityParsingServiceTests
{
    private readonly QuantityParsingService _sut = new();
    
    [Theory]
    [InlineData("2 tsp", 2, "tsp")]
    [InlineData("1.5 kg", 1.5, "kg")]
    [InlineData("250ml", 250, "ml")]
    [InlineData("3", 3, "handful")]  // default for no unit
    [InlineData("1 handful", 1, "handful")]
    public void Parse_ShouldHandleValidInputs(string input, decimal expectedQty, string expectedUnit)
    {
        var result = _sut.Parse(input);
        
        Assert.Equal(expectedQty, result.Quantity);
        Assert.Equal(expectedUnit, result.Unit.Code);
    }
    
    [Theory]
    [InlineData("2 cups")]  // Imperial not supported
    [InlineData("1 oz")]    // Imperial not supported  
    [InlineData("-5 g")]    // Negative quantity
    [InlineData("abc xyz")] // Invalid format
    public void Parse_ShouldRejectInvalidInputs(string input)
    {
        Assert.Throws<InvalidQuantityException>(() => _sut.Parse(input));
    }
    
    [Theory]
    [InlineData("teaspoon", "tsp")]
    [InlineData("tablespoon", "tbsp")]
    [InlineData("grams", "g")]
    [InlineData("gram", "g")]
    [InlineData("millilitres", "ml")]
    [InlineData("litres", "l")]
    public void Parse_ShouldNormalizeUnitNames(string input, string expected)
    {
        var result = _sut.Parse($"1 {input}");
        Assert.Equal(expected, result.Unit.Code);
    }
}
```

### 4.3 Shopping List Aggregation (TDD)
```csharp
// Tests first: Chefify.Tests/Unit/Application/ShoppingListAggregationTests.cs
public class ShoppingListAggregationTests
{
    private readonly ShoppingListAggregationService _sut;
    
    public ShoppingListAggregationTests()
    {
        var unitConverter = new UnitConversionService();
        _sut = new ShoppingListAggregationService(unitConverter);
    }
    
    [Fact]
    public void Aggregate_ShouldCombineSameIngredientsSameUnit()
    {
        // Arrange
        var items = new[]
        {
            CreateItem("flour", 200, "g"),
            CreateItem("flour", 300, "g")
        };
        
        // Act
        var result = _sut.Aggregate(items);
        
        // Assert
        Assert.Single(result);
        Assert.Equal(500, result.First().Quantity);
        Assert.Equal("g", result.First().Unit);
    }
    
    [Fact]
    public void Aggregate_ShouldConvertToLargerUnits()
    {
        // Arrange
        var items = new[]
        {
            CreateItem("flour", 800, "g"),
            CreateItem("flour", 700, "g")
        };
        
        // Act
        var result = _sut.Aggregate(items);
        
        // Assert
        Assert.Single(result);
        Assert.Equal(1.5m, result.First().Quantity);
        Assert.Equal("kg", result.First().Unit);
    }
    
    [Fact]
    public void Aggregate_ShouldHandleMixedUnits()
    {
        // Arrange
        var items = new[]
        {
            CreateItem("milk", 500, "ml"),
            CreateItem("milk", 0.5m, "l")
        };
        
        // Act
        var result = _sut.Aggregate(items);
        
        // Assert
        Assert.Single(result);
        Assert.Equal(1, result.First().Quantity);
        Assert.Equal("l", result.First().Unit);
    }
    
    [Fact]
    public void Aggregate_ShouldNotMixDifferentUnitTypes()
    {
        // Arrange
        var items = new[]
        {
            CreateItem("butter", 200, "g"),
            CreateItem("butter", 2, "tbsp")  // Can't convert volume to weight
        };
        
        // Act
        var result = _sut.Aggregate(items);
        
        // Assert
        Assert.Equal(2, result.Count());  // Kept separate
    }
}
```

## 5. Unit Conversion System (Simplified)

### 5.1 Conversion Service
```csharp
public class UnitConversionService : IUnitConversionService
{
    private readonly Dictionary<string, decimal> _toBaseMultipliers = new()
    {
        // Volume (base: ml)
        ["tsp"] = 5m,
        ["tbsp"] = 15m,
        ["ml"] = 1m,
        ["l"] = 1000m,
        
        // Weight (base: g)
        ["g"] = 1m,
        ["kg"] = 1000m,
    };
    
    public bool CanConvert(string fromUnit, string toUnit)
    {
        var from = new Unit(fromUnit);
        var to = new Unit(toUnit);
        
        // Can only convert within same type
        return from.Type == to.Type && from.Type != UnitType.Approximate;
    }
    
    public decimal Convert(decimal quantity, string fromUnit, string toUnit)
    {
        if (!CanConvert(fromUnit, toUnit))
            throw new InvalidConversionException($"Cannot convert {fromUnit} to {toUnit}");
            
        if (fromUnit == toUnit)
            return quantity;
            
        // Convert to base unit first
        var baseQuantity = quantity * _toBaseMultipliers[fromUnit];
        
        // Then to target unit
        return baseQuantity / _toBaseMultipliers[toUnit];
    }
    
    public (decimal Quantity, string Unit) OptimizeUnit(decimal quantity, string unit)
    {
        // Convert to more readable units
        // e.g., 1500g -> 1.5kg, 2000ml -> 2l
        
        if (unit == "g" && quantity >= 1000)
            return (quantity / 1000, "kg");
            
        if (unit == "ml" && quantity >= 1000)
            return (quantity / 1000, "l");
            
        if (unit == "kg" && quantity < 1)
            return (quantity * 1000, "g");
            
        if (unit == "l" && quantity < 1)
            return (quantity * 1000, "ml");
            
        return (quantity, unit);
    }
}
```

## 6. Frontend Components (React/TypeScript)

### 6.1 Smart Quantity Input
```typescript
// src/components/shopping/SmartQuantityInput.test.tsx
describe('SmartQuantityInput', () => {
  it('should parse valid metric inputs', () => {
    const onAdd = jest.fn();
    const { getByPlaceholderText, getByText } = render(
      <SmartQuantityInput onAdd={onAdd} />
    );
    
    const nameInput = getByPlaceholderText(/item name/i);
    const quantityInput = getByPlaceholderText(/quantity/i);
    
    fireEvent.change(nameInput, { target: { value: 'Flour' } });
    fireEvent.change(quantityInput, { target: { value: '500g' } });
    
    expect(getByText('→ 500 g')).toBeInTheDocument();
    
    fireEvent.click(getByText(/add to list/i));
    
    expect(onAdd).toHaveBeenCalledWith(500, 'g', 'Flour');
  });
  
  it('should reject imperial units', () => {
    const { getByPlaceholderText, queryByText } = render(
      <SmartQuantityInput onAdd={jest.fn()} />
    );
    
    const input = getByPlaceholderText(/quantity/i);
    fireEvent.change(input, { target: { value: '2 cups' } });
    
    expect(queryByText(/→/)).not.toBeInTheDocument();
  });
});

// src/components/shopping/SmartQuantityInput.tsx
export const SmartQuantityInput: React.FC<SmartQuantityInputProps> = ({ onAdd }) => {
  const [input, setInput] = useState('');
  const [itemName, setItemName] = useState('');
  const [parsed, setParsed] = useState<ParsedQuantity | null>(null);
  const [error, setError] = useState<string>('');
  
  useEffect(() => {
    if (input) {
      try {
        const result = parseQuantity(input);
        setParsed(result);
        setError('');
      } catch (e) {
        setParsed(null);
        if (input.includes('cup') || input.includes('oz') || input.includes('lb')) {
          setError('Only metric units are supported');
        }
      }
    }
  }, [input]);
  
  return (
    <div className="space-y-2">
      <input
        type="text"
        placeholder="Item name (e.g., Chicken breast)"
        value={itemName}
        onChange={(e) => setItemName(e.target.value)}
        className="w-full p-2 border rounded"
      />
      
      <div className="relative">
        <input
          type="text"
          placeholder="Quantity (e.g., '2 tbsp', '500g', '3')"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          className="w-full p-2 border rounded"
        />
        
        {parsed && (
          <div className="absolute right-2 top-2 text-sm text-green-600">
            → {parsed.quantity} {parsed.unit}
          </div>
        )}
        
        {error && (
          <div className="text-red-500 text-sm mt-1">{error}</div>
        )}
      </div>
      
      <button
        onClick={() => {
          if (parsed && itemName) {
            onAdd(parsed.quantity, parsed.unit, itemName);
            setInput('');
            setItemName('');
          }
        }}
        disabled={!parsed || !itemName}
        className="w-full p-2 bg-blue-500 text-white rounded disabled:bg-gray-300"
      >
        Add to list
      </button>
      
      <p className="text-xs text-gray-500">
        Supported: tsp, tbsp, ml, l, g, kg, handful
      </p>
    </div>
  );
};
```

## 7. Implementation Phases (Test-First)

### Phase 1: Foundation & Core Domain (Week 1)
1. **Write tests for domain entities** (User, MealPlan, ShoppingListItem)
2. **Implement domain models** to pass tests
3. **Set up Docker Compose** with PostgreSQL
4. **Configure OIDC authentication** with tests
5. **Create database migrations**
6. **Set up CI pipeline** to run tests

### Phase 2: Unit System & Parsing (Week 2)
1. **Write comprehensive tests** for unit parsing
2. **Implement Unit value object**
3. **Write tests for conversion service**
4. **Implement conversion logic**
5. **Create quantity parsing with edge cases**
6. **Integration tests for parsing pipeline**

### Phase 3: Recipe & Preferences (Week 3)
1. **Write API tests** for recipe endpoints
2. **Implement recipe search service**
3. **Test preference management**
4. **Build preference service**
5. **Create React components with tests**
6. **Integration tests for full flow**

### Phase 4: Meal Planning (Week 4)
1. **Test meal plan domain logic**
2. **Implement weekly planning service**
3. **Test calendar UI components**
4. **Build drag-and-drop interface**
5. **E2E tests for planning flow**

### Phase 5: Shopping List (Week 5)
1. **Test aggregation algorithms**
2. **Implement shopping list service**
3. **Test smart input components**
4. **Build shopping list UI**
5. **Integration tests for add/check flow**

### Phase 6: AI & Optimization (Week 6)
1. **Test recommendation logic**
2. **Implement basic algorithm**
3. **Test ingredient optimization**
4. **Build optimization service**
5. **Performance tests**
6. **Full system integration tests**

## 8. Testing Strategy

### 8.1 Test Pyramid
```
         /\
        /E2E\       (5%) - Critical user journeys
       /------\
      /  Integ  \   (20%) - API & database tests
     /----------\
    /    Unit     \ (75%) - Domain & service logic
   /--------------\
```

### 8.2 Test Coverage Goals
- **Domain Layer**: 100% coverage
- **Application Services**: 90% coverage
- **API Controllers**: 80% coverage
- **Frontend Components**: 85% coverage

### 8.3 Testing Tools
- **Backend**: xUnit, FluentAssertions, Moq, TestContainers
- **Frontend**: Jest, React Testing Library, MSW
- **E2E**: Playwright
- **Performance**: NBomber

## 9. Docker Development Setup

### 9.1 docker-compose.yml
```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: chefify
      POSTGRES_USER: chefify
      POSTGRES_PASSWORD: localdev
    ports:
      - "5432:5432"
    volumes:
      - ./database/init.sql:/docker-entrypoint-initdb.d/01-init.sql
      - ./recipes.sql:/docker-entrypoint-initdb.d/02-recipes.sql
      - postgres_data:/var/lib/postgresql/data

  api:
    build: 
      context: ./backend
      dockerfile: Dockerfile.dev
    environment:
      ConnectionStrings__Default: "Host=postgres;Database=chefify;Username=chefify;Password=localdev"
      OIDC_AUTHORITY: "${OIDC_AUTHORITY:-https://dev-oidc.example.com}"
      OIDC_CLIENT_ID: "${OIDC_CLIENT_ID:-chefify-local}"
      OIDC_CLIENT_SECRET: "${OIDC_CLIENT_SECRET:-secret}"
    ports:
      - "5000:80"
    volumes:
      - ./backend:/src
    depends_on:
      - postgres
    command: dotnet watch run --project /src/Chefify.Api/Chefify.Api.csproj

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile.dev
    environment:
      REACT_APP_API_URL: "http://localhost:5000"
      REACT_APP_OIDC_AUTHORITY: "${OIDC_AUTHORITY:-https://dev-oidc.example.com}"
      REACT_APP_OIDC_CLIENT_ID: "${OIDC_CLIENT_ID:-chefify-local}"
    ports:
      - "3000:3000"
    volumes:
      - ./frontend/src:/app/src
      - ./frontend/public:/app/public

  test-runner:
    build:
      context: ./backend
      dockerfile: Dockerfile.test
    environment:
      ConnectionStrings__Default: "Host=postgres;Database=chefify_test;Username=chefify;Password=localdev"
    volumes:
      - ./backend:/src
      - ./test-results:/results
    depends_on:
      - postgres
    command: dotnet test --logger "trx;LogFileName=/results/test-results.trx"

volumes:
  postgres_data:
```

## 10. Key Simplifications

1. **Only 8 supported units** - no imperial, no confusion
2. **Test-first development** - quality from the start
3. **Smart defaults** - "3" becomes "3 handful"
4. **Clear validation** - immediate feedback on unsupported units
5. **Automatic optimization** - 1500g becomes 1.5kg

This simplified, test-driven approach will result in a more maintainable and reliable system.