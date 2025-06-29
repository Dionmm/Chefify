CREATE SCHEMA IF NOT EXISTS recipes;

-- Main recipes table
CREATE TABLE IF NOT EXISTS recipes.recipes (
    objectid VARCHAR(255) PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    cuisine VARCHAR(255),
    season VARCHAR(255),
    badges TEXT[], -- Array of strings
    cook_time_minutes INTEGER,
    portions_available TEXT[], -- Array of strings
    allergens TEXT[], -- Array of strings
    rating_average VARCHAR(255),
    calories_per_portion DECIMAL,
    protein_per_portion DECIMAL,
    carbs_per_portion DECIMAL,
    fat_per_portion DECIMAL,
    ingredients TEXT[], -- Array of strings
    slug VARCHAR(255),
    before_you_start TEXT,
    updated_at TIMESTAMP,
    status VARCHAR(50)
);

-- Table for recipe steps
CREATE TABLE IF NOT EXISTS recipes.recipe_steps (
    id SERIAL PRIMARY KEY,
    recipe_id VARCHAR(255) REFERENCES recipes.recipes(objectid),
    position INTEGER,
    description TEXT,
    UNIQUE(recipe_id, position)
);

-- Table for ingredients
CREATE TABLE IF NOT EXISTS recipes.ingredients (
    id VARCHAR(255) PRIMARY KEY,
    name TEXT NOT NULL
);

-- Table for recipe components (ingredient amounts)
CREATE TABLE IF NOT EXISTS recipes.recipe_components (
    id SERIAL PRIMARY KEY,
    recipe_id VARCHAR(255) REFERENCES recipes.recipes(objectid),
    ingredient_id VARCHAR(255) REFERENCES recipes.ingredients(id),
    unit VARCHAR(50),
    unit_quantity DECIMAL,
    source_id VARCHAR(255),  -- Original ID from the source system (for reference only)
    UNIQUE(recipe_id, ingredient_id, unit, unit_quantity)  -- Ensure we don't duplicate identical components
);
