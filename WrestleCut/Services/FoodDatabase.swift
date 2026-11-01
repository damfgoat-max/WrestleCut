import Foundation

enum FoodDatabase {
    static let dislikeOptions: [DislikeOption] = [
        .init(id:"broccoli", name:"Broccoli", category:"Vegetables"), .init(id:"spinach", name:"Spinach", category:"Vegetables"),
        .init(id:"kale", name:"Kale", category:"Vegetables"), .init(id:"cauliflower", name:"Cauliflower", category:"Vegetables"),
        .init(id:"brussels", name:"Brussels Sprouts", category:"Vegetables"), .init(id:"mushrooms", name:"Mushrooms", category:"Vegetables"),
        .init(id:"onions", name:"Onions", category:"Vegetables"), .init(id:"peppers", name:"Bell Peppers", category:"Vegetables"),
        .init(id:"chicken", name:"Chicken", category:"Proteins"), .init(id:"turkey", name:"Turkey", category:"Proteins"),
        .init(id:"beef", name:"Beef", category:"Proteins"), .init(id:"pork", name:"Pork", category:"Proteins"),
        .init(id:"salmon", name:"Salmon", category:"Proteins"), .init(id:"tuna", name:"Tuna", category:"Proteins"),
        .init(id:"shrimp", name:"Shrimp", category:"Proteins"), .init(id:"eggs", name:"Eggs", category:"Proteins"),
        .init(id:"tofu", name:"Tofu", category:"Proteins"), .init(id:"greek-yogurt", name:"Greek Yogurt", category:"Proteins"),
        .init(id:"rice", name:"Rice", category:"Carbs"), .init(id:"oats", name:"Oats / Oatmeal", category:"Carbs"),
        .init(id:"pasta", name:"Pasta", category:"Carbs"), .init(id:"bread", name:"Bread", category:"Carbs"),
        .init(id:"potato", name:"Potato / Sweet Potato", category:"Carbs"), .init(id:"quinoa", name:"Quinoa", category:"Carbs"),
        .init(id:"milk", name:"Milk / Dairy", category:"Allergies & Other"), .init(id:"peanuts", name:"Peanuts", category:"Allergies & Other"),
        .init(id:"tree-nuts", name:"Tree Nuts", category:"Allergies & Other"), .init(id:"soy", name:"Soy", category:"Allergies & Other"),
        .init(id:"gluten", name:"Gluten / Wheat", category:"Allergies & Other"), .init(id:"shellfish", name:"Shellfish", category:"Allergies & Other"),
    ]
    static let allFoods: [FoodItem] = [
        .init(id:"f1", name:"Grilled Chicken Breast", brand:"Tyson", category:"Protein", calories:165, proteinG:31, carbsG:0, fatG:3.6, sodiumMg:75, serving:"4 oz", barcode:"023700016501", priceEstimate:5.99),
        .init(id:"f2", name:"Ready Rice Original", brand:"Ben's Original", category:"Carbs", calories:210, proteinG:4, carbsG:45, fatG:2, sodiumMg:720, serving:"1 pouch", barcode:"038000138416", priceEstimate:2.49),
        .init(id:"f3", name:"Chocolate Protein Shake", brand:"Fairlife Core Power", category:"Protein", calories:230, proteinG:42, carbsG:8, fatG:3.5, sodiumMg:260, serving:"14 fl oz", barcode:"811620020981", priceEstimate:3.99),
        .init(id:"f4", name:"Greek Yogurt 0%", brand:"Fage", category:"Protein", calories:100, proteinG:18, carbsG:6, fatG:0, sodiumMg:65, serving:"170g", barcode:"689544083706", priceEstimate:1.79),
        .init(id:"f5", name:"Large Eggs", brand:"Eggland's Best", category:"Protein", calories:140, proteinG:12, carbsG:0, fatG:10, sodiumMg:140, serving:"2 eggs", barcode:"071100010415", priceEstimate:4.29),
        .init(id:"f6", name:"Rolled Oats", brand:"Quaker", category:"Carbs", calories:150, proteinG:5, carbsG:27, fatG:3, sodiumMg:5, serving:"40g", barcode:"030000010147", priceEstimate:4.99),
        .init(id:"f7", name:"Ground Turkey 93%", brand:"Jennie-O", category:"Protein", calories:170, proteinG:21, carbsG:0, fatG:10, sodiumMg:75, serving:"4 oz", barcode:"042222832109", priceEstimate:5.49),
        .init(id:"f8", name:"Atlantic Salmon Fillet", brand:"", category:"Protein", calories:208, proteinG:22, carbsG:0, fatG:13, sodiumMg:180, serving:"100g", barcode:"", priceEstimate:8.99),
        .init(id:"f9", name:"Tuna in Water", brand:"StarKist", category:"Protein", calories:90, proteinG:20, carbsG:0, fatG:1, sodiumMg:360, serving:"1 pouch", barcode:"080000055152", priceEstimate:1.49),
        .init(id:"f10", name:"Sweet Potato", brand:"", category:"Carbs", calories:112, proteinG:2, carbsG:26, fatG:0, sodiumMg:72, serving:"1 medium", barcode:"", priceEstimate:1.29),
        .init(id:"f11", name:"Rice Cakes", brand:"Quaker", category:"Snack", calories:70, proteinG:1, carbsG:14, fatG:0.5, sodiumMg:90, serving:"2 cakes", barcode:"030000169103", priceEstimate:3.29),
        .init(id:"f12", name:"Protein Bar Chocolate", brand:"Barebells", category:"Snack", calories:200, proteinG:20, carbsG:16, fatG:7, sodiumMg:210, serving:"1 bar", barcode:"7340001800421", priceEstimate:2.99),
        .init(id:"f13", name:"Cottage Cheese", brand:"Good Culture", category:"Protein", calories:110, proteinG:14, carbsG:5, fatG:2.5, sodiumMg:350, serving:"110g", barcode:"860000012345", priceEstimate:3.79),
        .init(id:"f14", name:"Banana", brand:"", category:"Fruit", calories:105, proteinG:1.3, carbsG:27, fatG:0.4, sodiumMg:1, serving:"1 medium", barcode:"", priceEstimate:0.69),
        .init(id:"f15", name:"Electrolyte Drink", brand:"Liquid I.V.", category:"Hydration", calories:45, proteinG:0, carbsG:11, fatG:0, sodiumMg:490, serving:"1 stick", barcode:"850039286012", priceEstimate:1.99),
        .init(id:"f16", name:"Peanut Butter", brand:"Jif", category:"Fats", calories:190, proteinG:7, carbsG:8, fatG:16, sodiumMg:140, serving:"2 tbsp", barcode:"051500720162", priceEstimate:3.99),
        .init(id:"f17", name:"Greek Yogurt Plain Nonfat", brand:"Great Value (Walmart)", category:"Protein", calories:90, proteinG:15, carbsG:6, fatG:0, sodiumMg:60, serving:"150g cup", barcode:"681131180603", priceEstimate:0.98),
        .init(id:"f18", name:"Protein Bar Cookies & Cream", brand:"Kirkland Signature (Costco)", category:"Snack", calories:190, proteinG:21, carbsG:22, fatG:7, sodiumMg:190, serving:"1 bar", barcode:"096619168449", priceEstimate:1.49),
        .init(id:"f19", name:"Rotisserie Chicken", brand:"Costco Kirkland", category:"Protein", calories:140, proteinG:26, carbsG:0, fatG:4, sodiumMg:460, serving:"3 oz meat", barcode:"000000354886", priceEstimate:4.99),
        .init(id:"f20", name:"Instant Oatmeal Original", brand:"Quaker", category:"Carbs", calories:100, proteinG:3, carbsG:19, fatG:2, sodiumMg:75, serving:"1 packet", barcode:"030000010208", priceEstimate:0.49),
        .init(id:"f21", name:"Deli Turkey Breast", brand:"Boar's Head", category:"Protein", calories:60, proteinG:10, carbsG:1, fatG:1, sodiumMg:450, serving:"2 oz", barcode:"042308314357", priceEstimate:6.99),
        .init(id:"f22", name:"Chocolate Milk Low Fat", brand:"Fairlife", category:"Protein", calories:140, proteinG:13, carbsG:13, fatG:4.5, sodiumMg:150, serving:"240ml", barcode:"811620020011", priceEstimate:1.99),
        .init(id:"f23", name:"Frozen Berry Blend", brand:"Great Value (Walmart)", category:"Fruit", calories:70, proteinG:1, carbsG:17, fatG:0, sodiumMg:0, serving:"140g", barcode:"681131180450", priceEstimate:2.48),
        .init(id:"f24", name:"Electrolyte Drink Mix Zero", brand:"Gatorade Zero", category:"Hydration", calories:5, proteinG:0, carbsG:1, fatG:0, sodiumMg:160, serving:"1 packet", barcode:"052000041968", priceEstimate:0.79),
        // Generic reference foods (standard USDA-style values for plain, unbranded foods).
        // These fill in plain-plate photos — rice, broccoli, plain grilled meats — with
        // realistic wrestler portions when no branded/web match exists. Always editable.
        .init(id:"g1", name:"White Rice, cooked", brand:"", category:"Reference", calories:205, proteinG:4.3, carbsG:45, fatG:0.4, sodiumMg:1, serving:"1 cup cooked", barcode:"", priceEstimate:0),
        .init(id:"g2", name:"Broccoli, cooked", brand:"", category:"Reference", calories:55, proteinG:3.7, carbsG:11, fatG:0.6, sodiumMg:30, serving:"1 cup", barcode:"", priceEstimate:0),
        .init(id:"g3", name:"Green Beans, cooked", brand:"", category:"Reference", calories:44, proteinG:2.4, carbsG:10, fatG:0.2, sodiumMg:1, serving:"1 cup", barcode:"", priceEstimate:0),
        .init(id:"g4", name:"Garden Salad (no dressing)", brand:"", category:"Reference", calories:33, proteinG:2.6, carbsG:6, fatG:0.4, sodiumMg:28, serving:"2 cups greens + veg", barcode:"", priceEstimate:0),
        .init(id:"g5", name:"Grilled Chicken Breast (plain)", brand:"", category:"Reference", calories:280, proteinG:53, carbsG:0, fatG:6, sodiumMg:128, serving:"6 oz", barcode:"", priceEstimate:0),
        .init(id:"g6", name:"Ground Beef 90% lean, cooked", brand:"", category:"Reference", calories:200, proteinG:23, carbsG:0, fatG:11, sodiumMg:75, serving:"4 oz", barcode:"", priceEstimate:0),
        .init(id:"g7", name:"Sirloin Steak, grilled", brand:"", category:"Reference", calories:320, proteinG:48, carbsG:0, fatG:13, sodiumMg:105, serving:"6 oz", barcode:"", priceEstimate:0),
        .init(id:"g8", name:"Pork Chop, grilled", brand:"", category:"Reference", calories:210, proteinG:26, carbsG:0, fatG:11, sodiumMg:65, serving:"4 oz", barcode:"", priceEstimate:0),
        .init(id:"g9", name:"Cod / White Fish, baked", brand:"", category:"Reference", calories:138, proteinG:29, carbsG:0, fatG:1.5, sodiumMg:125, serving:"5 oz", barcode:"", priceEstimate:0),
        .init(id:"g10", name:"Shrimp, cooked", brand:"", category:"Reference", calories:112, proteinG:24, carbsG:1, fatG:1, sodiumMg:160, serving:"4 oz", barcode:"", priceEstimate:0),
        .init(id:"g11", name:"Pasta, cooked (plain)", brand:"", category:"Reference", calories:220, proteinG:8, carbsG:43, fatG:1.3, sodiumMg:1, serving:"1 cup cooked", barcode:"", priceEstimate:0),
        .init(id:"g12", name:"Mashed Potato", brand:"", category:"Reference", calories:214, proteinG:4, carbsG:35, fatG:7, sodiumMg:340, serving:"1 cup", barcode:"", priceEstimate:0),
        .init(id:"g13", name:"French Fries", brand:"", category:"Reference", calories:365, proteinG:4, carbsG:48, fatG:17, sodiumMg:250, serving:"1 medium order", barcode:"", priceEstimate:0),
        .init(id:"g14", name:"Cheese Pizza", brand:"", category:"Reference", calories:285, proteinG:12, carbsG:36, fatG:10, sodiumMg:640, serving:"1 slice", barcode:"", priceEstimate:0),
        .init(id:"g15", name:"Cheeseburger", brand:"", category:"Reference", calories:303, proteinG:15, carbsG:29, fatG:12, sodiumMg:530, serving:"1 burger", barcode:"", priceEstimate:0),
        .init(id:"g16", name:"Avocado", brand:"", category:"Reference", calories:160, proteinG:2, carbsG:9, fatG:15, sodiumMg:7, serving:"1/2 fruit", barcode:"", priceEstimate:0),
        .init(id:"g17", name:"Apple", brand:"", category:"Reference", calories:95, proteinG:0.5, carbsG:25, fatG:0.3, sodiumMg:1, serving:"1 medium", barcode:"", priceEstimate:0),
        .init(id:"f25", name:"Skittles Original", brand:"Skittles (Mars)", category:"Snack", calories:120, proteinG:0, carbsG:29, fatG:1.5, sodiumMg:10, serving:"30 pieces (30g)", barcode:"040000506765", priceEstimate:1.25),
        .init(id:"g19", name:"Candy / Jelly Beans", brand:"", category:"Reference", calories:105, proteinG:0, carbsG:26, fatG:0, sodiumMg:10, serving:"1 oz (about 10 jelly beans)", barcode:"", priceEstimate:0),
        .init(id:"g18", name:"Orange Juice", brand:"", category:"Reference", calories:112, proteinG:1.7, carbsG:26, fatG:0.5, sodiumMg:2, serving:"1 cup", barcode:"", priceEstimate:0),
    ]
    static func foods(avoiding disliked: [String]) -> [FoodItem] {
        allFoods.filter { food in !disliked.contains(where: { food.name.lowercased().contains($0.replacingOccurrences(of:"-", with:" ")) || food.id == $0 }) }
    }
    static func mealPlan(profile: UserProfile, variant: Int = 0) -> [MealSuggestion] {
        let foods = foods(avoiding: profile.dislikedFoodIDs)
        func pick(_ idx: Int, fallback: FoodItem) -> FoodItem { foods.isEmpty ? fallback : foods[(idx+variant) % foods.count] }
        let chicken = allFoods[0], rice = allFoods[1], shake = allFoods[2], yogurt = allFoods[3], eggs = allFoods[4], oats = allFoods[5]
        return [
            MealSuggestion(mealType:"Breakfast", title:"Champion Oats & Eggs", items:[pick(5, fallback:oats), pick(4, fallback:eggs)], prepMinutes:10, instructions:"Cook oats with water. Scramble eggs on the side. Add cinnamon, no sugar.", ingredients:["Oats","Eggs","Cinnamon"]),
            MealSuggestion(mealType:"Lunch", title:"Grilled Chicken & Rice", items:[pick(0, fallback:chicken), pick(1, fallback:rice)], prepMinutes:12, instructions:"Grill chicken to 165°F. Microwave rice pouch 90 sec. Add steamed veg you like.", ingredients:["Chicken breast","Ready rice"]),
            MealSuggestion(mealType:"Dinner", title:"Lean Protein Plate", items:[pick(6, fallback:allFoods[6]), pick(9, fallback:allFoods[9])], prepMinutes:15, instructions:"Cook protein through. Roast sweet potato at 425°F for 25 min or microwave 6 min.", ingredients:["Lean protein","Sweet potato"]),
            MealSuggestion(mealType:"Snack", title:"High-Protein Recovery", items:[pick(2, fallback:shake), pick(3, fallback:yogurt)], prepMinutes:2, instructions:"Shake cold after practice. Yogurt if still hungry — protein protects muscle in a deficit.", ingredients:["Protein shake","Greek yogurt"]),
        ]
    }
}

enum StoreService {
    static func nearbyStores(zip: String, for food: FoodItem) -> [StoreInfo] {
        // Deterministic local demo data — no location is sent anywhere. In production, replace with a retailer API.
        // Seeded by zip so results are stable offline.
        let seed = zip.unicodeScalars.reduce(0){$0+Int($1.value)}
        let base: [(String,Double,String)] = [("Walmart",1.2,"$"),("Kroger",2.1,"$$"),("Aldi",2.8,"$"),("Publix",3.4,"$$"),("Whole Foods Market",4.6,"$$$"),("Target",1.9,"$$")]
        return base.enumerated().map { i, s in
            StoreInfo(name:s.0, distanceMiles: s.1 + Double((seed+i*7)%10)/10.0, priceLevel:s.2, address:"Near \(zip.isEmpty ? "you" : zip)", carriesNote: food.brand.isEmpty ? "Usually in produce / fresh section" : "Carries \(food.brand) — est. $\(String(format:"%.2f", food.priceEstimate))")
        }.sorted{$0.distanceMiles<$1.distanceMiles}
    }
}
